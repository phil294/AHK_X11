require "./ahk-string"

# can start a completely fresh and isolated ahk execution instance with its own
# variables etc. All properties can and will be heavily accessed from outside (commands).
class Runner
	property user_vars = {} of String => String
	property escape_char = '`' # todo at build time?

	def run(ins : Cmd)
		while ins
			result = ins.run(self)
			if ins.class.control_flow
				if result
					ins = ins.je
				else
					ins = ins.jne
				end
			else
				ins = ins.next
			end
		end
	end

	def str(str)
		AhkString.process(str, escape_char, user_vars) do |missing_var|
			""
		end
	end
end