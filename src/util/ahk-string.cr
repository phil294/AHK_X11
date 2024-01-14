class Util::AhkString
	# Substitute all %var% with their respective values by yielding each var name,
	# and convert special chars such as `n => \n.
	# This allows computation of pseudo-variable values at runtime, such as %A_Now%.
	def self.parse_string(str, escape_char : Char, *, no_variable_substitution = false)
		escape = false
		current_var_name : String::Builder? = nil
		String.build do |build|
			str.each_char_with_index do |char, i|
				if ! escape && char == escape_char
					escape = true
				else
					if escape
						char = case char
						when 'n' then '\n'
						when 't' then '\t'
						when 'r' then '\r'
						when 'v' then '\v'
						when 'a' then '\a'
						when 'f' then '\f'
						else char
						end
						build << char
					elsif ! no_variable_substitution && char == '%'
						if ! current_var_name
							current_var_name = String::Builder.new
						else
							var = yield current_var_name.to_s
							current_var_name = nil
							build << var
						end
					elsif current_var_name
						current_var_name << char
					else
						build << char
					end
					escape = false
				end
			end
			raise Run::RuntimeException.new "missing ending percent sign. Line content: '#{str}'" if current_var_name
		end
	end
	# Parses all `^+c{Tab up}` etc., including normal keys, and yields the key infos.
	# When *implicit_braces* is set, there should be no `{}` around key names and
	# thus everything is treated as a single key press (such as Hotkey definitions).
	# In this case, `a b` would be an error, when it otherwise wouldn't.
	# FIXME: make str.downcase because fc88e1b. This fix was lost while merging and might need to be applied in more (all?) invocations of parse_key_combinations / where else? do it in here?
	def self.parse_key_combinations(str, escape_char : Char, *, implicit_braces = false)
		escape = false
		modifiers = Run::KeyCombination::Modifiers.new
		blind = false
		str = str.sub("<^>!", "\0")
		iter = str.each_char
		while (char = iter.next) != Iterator::Stop::INSTANCE
			if ! escape && char == escape_char
				escape = true
			else
				key_name = nil
				up = false
				down = false
				repeat = 1
				if escape
					key_name = char.to_s
				else
					case char
					when '^' then modifiers.ctrl = true
					when '+' then modifiers.shift = true
					when '!' then modifiers.alt = true
					when '#' then modifiers.win = true
					when '\0' then modifiers.altgr = true
					when '$' then
					else
						if implicit_braces || char == '{'
							key_name = ""
							key_name += char.as(Char) if implicit_braces
							while (char = iter.next) != Iterator::Stop::INSTANCE
								break if ! implicit_braces && char == '}'
								key_name += char.as(Char)
							end
							split = key_name.split(" ")
							if split.size == 2
								case what = split[1].downcase
								when "up" then up = true
								when "down" then down = true
								else
									repeat = what.to_i?
									raise Run::RuntimeException.new "key name '#{key_name}' not understood" if ! repeat
								end
								key_name = split[0]
							end
						else
							key_name = char.to_s
						end
					end
				end
				escape = false
				if key_name
					if key_name.downcase == "blind"
						blind = true
					else
						{% if ! flag?(:release) %}
							puts "[debug] #{key_name}"
						{% end %}
						yield Run::KeyCombination.new(key_name.downcase, text: nil, modifiers: modifiers, up: up, down: down, repeat: repeat, blind: blind)
						modifiers = Run::KeyCombination::Modifiers.new
						blind = false
					end
				end
			end
		end
	end
	# :ditto:
	# Returns empty array on parse error
	def self.parse_key_combinations(str, escape_char : Char, *, implicit_braces = false)
		combos = [] of Run::KeyCombination
		begin
			self.parse_key_combinations(str, escape_char, implicit_braces: implicit_braces) do |combo|
				combos << combo if combo
			end
		rescue e : Run::RuntimeException
			return [] of Run::KeyCombination
		end
		combos
	end

	# Parses single-char-numbers combinations with optional spaces in between,
	# e.g. `A1B2.1` or `*0 c100` and yields each char-number combination (downcase).
	def self.parse_letter_options(str, escape_char : Char)
		n = ""
		letter = nil
		str.each_char do |char|
			case char
			when ' ' then next
			# TODO: better syntax without having to resort back to elsif?
			when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'
				n += char
			else
				if letter
					yield letter.downcase, n.to_f?
				end
				n = ""
				letter = char
			end
		end
		if letter
			yield letter.downcase, n.to_f?
		end
	end

	# Parses space/tab-delimited words, each optionally containing a `-` or `+` or
	# numbers (anywhere!), and retrieve those infos separated (downcase).
	# Every word is also treated as a single letter + body as a second entry.
	# e.g. `+center ab8cd2` returns (pseudo) `{ "center" => {plus: true}, "c" => {v: "enter", plus: true}, "abcd" => {n: 82}, "a" => {v: "b8cd2"} }`
	def self.parse_word_options(str, escape_char : Char)
		ret = {} of String => NamedTuple(n: Int64?, v: String, minus: Bool, plus: Bool)
		str.split().each do |part|
			minus = false
			plus = false
			n = ""
			word = ""
			part.each_char do |char|
				case char
				when '-' then minus = true
				when '+' then plus = true
				when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
					n += char
				when 'x'
					if n[-1]? == '0'
						n += 'x'
					else
						word += char
					end
				else
					word += char
				end
			end
			down = word.downcase
			ret[down] = ret[part[0].downcase.to_s] = {
				n: n.to_i64?(prefix: true) || nil,
				v: part[1..]? || "",
				minus: minus,
				plus: plus
			}
		end
		ret
	end
end