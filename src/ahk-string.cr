class AhkString
	# Substitute all %var% with their respective values, and get missing vars via block.
	# This allows computation of pseudo-variable values at runtime, such as %A_Now%.
	def self.process(str, escape_char, vars)
		last = nil
		escape = false
		var_start = nil
		String.build do |build|
			str.each_char_with_index do |char, i|
				if char == escape_char
					escape = true
				else
					if escape
						build << char
					elsif char == '%'
						if var_start.nil?
							var_start = i + 1
						else
							var_name = str[var_start..i-1].downcase # todo empty vars probbaly reuslt in garbage
							var = vars[var_name]?
							var = yield var_name if ! var
							build << var
							var_start = nil
						end
					elsif var_start.nil?
						build << char
					end
					escape = false
				end
			end
			# if var_start todo syntax error? build error? how does ahk do it?
		end
	end
end