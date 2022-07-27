require "./ahk-string"

module Run
	# see Thread.settings
	private struct ThreadSettings
		property last_found_window : XDo::Window?
	end

	# AHK threads are no real threads but pseudo-threads and pretty much like crystal fibers,
	# except they're not cooperative at all; they take each other's place (prioritized) and
	# continue until their individual end. Threads never really run in parallel:
	# There's always one "current thread"
	class Thread
		getter runner : Runner
		# `Settings` are configuration properties that may or may not be modified by various
		# `Cmd`s and affect the script's execution logic. Settings are **never**, however,
		# directly exposed to the user as `%variables%`, but may be accessed by dedicated
		# commands. If a setting refers to a built-in variable name, it should live in
		# `@built_in_static_vars` instead, either in `Runner` or `Thread`, depending on its scope.
		#
		# Each thread starts with its own set of settings (e.g. CoordMode),
		# the default can be changed in the auto execute section.
		getter settings : ThreadSettings
		# These thread-specific vars are only changed by the program and also exposed
		# to the user. Also see `settings`.
		# User-modifiable variables are inherently global and thus live in `Runner`.
		@built_in_static_vars = {
			"errorlevel" => "0"
		}
		@stack = [] of Cmd::Base
		getter priority = 0
		@exit_code = 0
		getter done = false
		@result_channel : Channel(Int32?)?
		def initialize(@runner, start, @priority, @settings)
			@stack << start
		end

		# Spawns the `do_next` fiber if it isn't running already and returns the result channel.
		protected def next
			result_channel = @result_channel
			return result_channel if result_channel
			result_channel = @result_channel = Channel(Int32?).new
			spawn same_thread: true do
				result = do_next
				result_channel.send(result)
				result_channel.close
				@result_channel = nil
				result
			end
			result_channel
		end
		# returns exit code or nil if this thread isn't done yet
		private def do_next
			cmd = @stack.last?
			if ! cmd
				@done = true
				return @exit_code
			end
			stack_i = @stack.size - 1

			parsed_args = cmd.args.map { |arg| str(arg) }

			begin
				result = cmd.run(self, parsed_args)
			rescue e : RuntimeException
				msg = "Runtime error in line #{cmd.line_no+1}:\n#{e.message}.\n\nThe current thread will exit."
				@runner.gui.msgbox msg
				STDERR.puts msg
				@done = true
				@exit_code = 2
				return @exit_code
			end

			next_cmd = cmd.next
			if cmd.class.conditional
				if result
					next_cmd = cmd.je
				else
					next_cmd = cmd.jne
				end
			elsif cmd.class.sets_error_level
				raise "Result should be String for ErrorLevel command??" if ! result.is_a?(String)
				set_thread_built_in_static_var("ErrorLevel", result)
			end
			# current stack el may have been altered by prev cmd.run(), in which case disregard the normal flow
			if @stack[stack_i]? == cmd # not altered
				if ! next_cmd
					@stack.delete_at(stack_i) # thread finished
				else
					@stack[stack_i] = next_cmd # proceed
				end
			end
			nil
		end

		def gosub(label)
			cmd = @runner.labels[label]?
			raise RuntimeException.new "gosub: target label '#{label}' does not /st" if ! cmd
			@stack << cmd
		end
		def goto(label)
			cmd = @runner.labels[label]?
			raise RuntimeException.new "goto: target label '#{label}' does not exist" if ! cmd
			@stack[@stack.size - 1] = cmd
		end
		def return
			@stack.pop
		end
		def exit(code)
			@exit_code = code || 0
			@stack.clear
		end

		# Get the value of both thread-local and global values,
		# regardless if user set or built-in.
		# Case insensitive
		def get_var(var)
			down = var.downcase
			@built_in_static_vars[down]? || @runner.get_global_var(down) || ""
		end
		# `var` is case insensitive
		def set_thread_built_in_static_var(var, value)
			@built_in_static_vars[var.downcase] = value
		end

		# Substitute all %var% with their respective values, no matter where from.
		def str(str)
			AhkString.process(str, @runner.settings.escape_char) do |var_name_lookup|
				get_var(var_name_lookup)
			end
		end
	end
end