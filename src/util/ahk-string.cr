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
	def self.parse_key_combinations_to_charcodemap(str, escape_char : Char, x11 : Run::X11, implicit_braces = false)
		self.parse_key_combinations(str, escape_char, implicit_braces: implicit_braces) do |combo|
			key_map = XDo::LibXDo::Charcodemap.new
			mouse_button : XDo::Button? = nil
			if combo.keysym < 10
				mouse_button = case combo.keysym
				when 1 then XDo::Button::Left
				when 2 then XDo::Button::Middle
				when 3 then XDo::Button::Right
				when 4 then XDo::Button::ScrollUp
				when 5 then XDo::Button::ScrollDown
				when 6 then XDo::Button::ScrollLeft
				when 7 then XDo::Button::ScrollRight
				when 8 then XDo::Button::Button8
				when 9 then XDo::Button::Button9
				end
			else
				key_map.code = x11.keysym_to_keycode(combo.keysym)
				key_map.modmask = combo.modifiers
			end
			combo.repeat.times do
				if combo.down || ! combo.up
					yield [key_map], true, mouse_button, combo
				end
				if combo.up || ! combo.down
					yield [key_map], false, mouse_button, combo
				end
			end
		end
	end
	# :ditto:
	def self.parse_key_combinations(str, escape_char : Char, *, implicit_braces = false)
		escape = false
		modifiers = 0_u32
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
					when '^' then modifiers |= ::X11::ControlMask
					when '+' then modifiers |= ::X11::ShiftMask
					when '!' then modifiers |= ::X11::Mod1Mask
					when '#' then modifiers |= ::X11::Mod4Mask
					when '\0' then modifiers |= ::X11::Mod5Mask
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
					if key_name.size == 1 && key_name.upcase != key_name.downcase && key_name.upcase == key_name
						modifiers |= ::X11::ShiftMask
					end
					keysym = Run::X11.ahk_key_name_to_keysym(key_name)
					# TODO: why the typecheck / why not in x11.cr?
					raise Run::RuntimeException.new "key name '#{key_name}' not found" if ! keysym || ! keysym.is_a?(Int32)

					{% if ! flag?(:release) %}
						puts "[debug] #{key_name}: #{keysym}/#{modifiers}" # TODO:
					{% end %}
					yield Run::KeyCombination.new(key_name.downcase, keysym.to_u64, modifiers, up, down, repeat)

					modifiers = 0_u32
				end
			end
		end
	end
	# :ditto:
	def self.parse_key_combinations(str, escape_char : Char, *, implicit_braces = false)
		combos = [] of Run::KeyCombination
		self.parse_key_combinations(str, escape_char, implicit_braces: implicit_braces) do |combo|
			combos << combo
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