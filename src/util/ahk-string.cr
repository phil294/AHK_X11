class Util::AhkString
	# Substitute all %var% with their respective values by yielding each var name,
	# and convert special chars such as `n => \n.
	# This allows computation of pseudo-variable values at runtime, such as %A_Now%.
	def self.substitute_variables(str, escape_char : Char)
		escape = false
		var_start = nil
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
					elsif char == '%'
						if var_start.nil?
							var_start = i + 1
						else
							var_name = str[var_start..i-1]
							var = yield var_name
							build << var
							var_start = nil
						end
					elsif var_start.nil?
						build << char
					end
					escape = false
				end
			end
			# INCOMPAT: only raises at runtime, on ahk it's build time
			raise Run::RuntimeException.new "missing ending percent sign. Line content: '#{str}'" if var_start
		end
	end

	# Parses all ^+c{Tab up} etc., including normal keys, and converts it all into a yielded
	# sequence of charcodemaps.
	def self.parse_keys(str, escape_char : Char, x11 : Run::X11)
		escape = false
		modifiers = 0
		iter = str.each_char
		while (char = iter.next) != Iterator::Stop::INSTANCE
			if ! escape && char == escape_char # This escape char stuff *could* be externalized into a custom Iterator, maybe putting it into global/string.cr, but that would only barely reduce LOC
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
					when '{'
						key_name = ""
						while (char = iter.next) != Iterator::Stop::INSTANCE
							break if char == '}'
							key_name += char.as(Char)
						end
						split = key_name.split(" ")
						if split.size == 2
							case what = split[1].downcase
							when "up" then up = true
							when "down" then down = true
							else
								repeat = what.to_i?(strict: true)
								raise Run::RuntimeException.new "key name '#{key_name}' not understood" if ! repeat
							end
							key_name = split[0]
						end
					else
						key_name = char.to_s
					end
				end
				escape = false
				if key_name
					keysym = x11.ahk_key_name_to_keysym(key_name)
					raise Run::RuntimeException.new "key name '#{key_name}' not found" if ! keysym || ! keysym.is_a?(Int32)
					key_map = XDo::LibXDo::Charcodemap.new
					key_map.code = x11.keysym_to_keycode(keysym.to_u64)
					key_map.modmask = modifiers
					repeat.times do
						if down || ! up
							yield [key_map], true
						end
						if up || ! down
							yield [key_map], false
						end
					end
					modifiers = 0
				end
			end
		end
	end

	# Parses single-char-numbers combinations with optional spaces in between,
	# e.g. `A1B2` or `*0 c100` and yields each char-number combination.
	def self.parse_letter_options(str, escape_char : Char)
		iter = str.each_char
		n = ""
		letter = nil
		while (char = iter.next) != Iterator::Stop::INSTANCE
			case char
			when ' ' then next
			when /[0-9]/
				n += char.as(Char)
			else
				if letter
					yield letter, n.to_i?(strict: true)
				end
				n = ""
				letter = char.as(Char)
			end
		end
		if letter
			yield letter, n.to_i?(strict: true)
		end
	end
end