class AhkString
	# Substitute all %var% with their respective values by yielding each var name.
	# This allows computation of pseudo-variable values at runtime, such as %A_Now%.
	def self.process(str, escape_char : Char)
		last = nil
		escape = false
		var_start = nil
		String.build do |build|
			str.each_char_with_index do |char, i|
				if ! escape && char == escape_char
					escape = true
				else
					if escape
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
			raise RuntimeException.new "missing ending percent sign. Line content: '#{str}'" if var_start
		end
	end
end