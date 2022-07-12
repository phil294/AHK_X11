require "./ahk-string"
require "./thread"

module Run
	# can start a completely fresh and isolated ahk execution instance with its own
	# variables etc. All properties can and will be heavily accessed from outside (commands).
	class Runner
		@user_vars = {} of String => String
		@escape_char = '`'
		protected getter labels : Hash(String, Cmd)
		@threads = [] of Thread
		@exit_code = 0

		def initialize(@labels, @auto_execute_section : Cmd, @escape_char) # todo force positional params with ** ?
			spawn_thread @auto_execute_section
		end

		def spawn_thread(cmd)
			thread = Thread.new(self, cmd)
			@threads << thread
			clock
		end

		private def clock
			while thread = @threads.last?
				exit_code = thread.next
				if @threads.last != thread
					# we're not top level anymore, something more important came along.
					# clock is now running in that thread instead.
					return
				end
				if ! exit_code.nil?
					@exit_code = exit_code
					@threads.pop
				end
			end
			::exit @exit_code
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
end