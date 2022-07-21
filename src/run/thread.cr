module Run
	# ahk threads are no real threads but pretty much like crystal fibers, except they're not
	# cooperative at all; they take each other's place (prioritized) and continue until their individual end.
	# Threads never really run in parallel: There's always one "current thread"
	class Thread
		getter runner : Runner
		# each threads starts with its own set of settings (e.g. CoordMode),
		# the default can be changed in the auto execute section
		getter settings : ThreadSettings
		@stack = [] of Cmd::Base
		getter priority = 0
		@exit_code = 0
		getter done = false
		@result_channel : Channel(Int32?)?
		def initialize(@runner, start, @priority, @settings)
			@stack << start
		end

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

			parsed_args = cmd.args.map { |arg| @runner.str(arg) }

			begin
				result = cmd.run(self, parsed_args)
			rescue e : RuntimeException
				# TODO: msgbox
				puts "Runtime error in line #{cmd.line_no+1}: '#{e.message}'. The current thread will exit."
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
			end
			# current stack el may have been altered by prev cmd.run(), in which case disregard the normal flow
			if @stack[stack_i]? == cmd # not altered
				if ! next_cmd
					@stack.delete_at(stack_i)
				else
					@stack[stack_i] = next_cmd
				end
			end
			nil
		end

		def gosub(label)
			cmd = @runner.labels[label]?
			raise RuntimeException.new "gosub: target label '#{label}' does not exist" if ! cmd
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
	end
	private struct ThreadSettings
		property last_found_window : XDo::Window?
	end
end