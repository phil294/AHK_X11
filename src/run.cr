require "./ahk-string"

# can start a completely fresh and isolated ahk execution instance with its own
# variables etc. All properties can and will be heavily accessed from outside (commands).
class Runner
	@user_vars = {} of String => String
	@escape_char = '`'
	@labels : Hash(String, Cmd)
	@exit_code = 0
	@stack = [] of Cmd
	def initialize(@labels, auto_execute_section : Cmd?, @escape_char) # todo force positional params with ** ?
		@stack << auto_execute_section if auto_execute_section
	end
	def run
		while ins = @stack.last?
			stack_i = @stack.size - 1
			result = ins.run(self)
			next_ins = ins.next
			if ins.class.control_flow
				if result
					next_ins = ins.je
				else
					next_ins = ins.jne
				end
			end
			# current stack el may have been altered by prev ins.run(), in which case disregard the normal flow
			if @stack[stack_i]? == ins # not altered
				if ! next_ins
					@stack.delete_at(stack_i)
				else
					@stack[stack_i] = next_ins
				end
			end
		end
		::exit @exit_code
	end
	def gosub(label)
		cmd = @labels[label]?
		raise RuntimeException.new "gosub: label '#{label}' not found" if ! cmd
		@stack << cmd
	end
	def goto(label)
		cmd = @labels[label]?
		raise RuntimeException.new "goto: label '#{label}' not found" if ! cmd
		@stack[@stack.size - 1] = cmd
	end
	def return
		@stack.pop
	end
	def exit(code)
		@exit_code = code || 0
		@stack.clear
	end

	def get_var(var)
		@user_vars[var.downcase]? || ""
	end
	def set_var(var, value)
		@user_vars[var.downcase] = value
	end
	def print_vars
		puts @user_vars
	end
	def str(str)
		AhkString.process(str, @escape_char) do |varname_lookup|
			get_var(varname_lookup)
		end
	end
end