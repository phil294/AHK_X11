require "x_do"
require "./display/gui"
require "./display"
require "../util/ahk-string"

module Run
	enum CoordMode
		SCREEN
		RELATIVE
	end

	# see Thread.settings
	private struct ThreadSettings
		property last_found_window : XDo::Window?
		property msgbox_response : Gui::MsgBoxButton?
		property coord_mode_tooltip = CoordMode::RELATIVE
		property coord_mode_pixel = CoordMode::RELATIVE
		property coord_mode_mouse = CoordMode::RELATIVE
		property coord_mode_caret = CoordMode::RELATIVE
		property coord_mode_menu = CoordMode::RELATIVE
	end

	# see Thread.cache
	private struct ThreadCache
		getter window_by_id = {} of UInt64 => XDo::Window
		getter frame_by_id = {} of UInt64 => ::Atspi::Accessible
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
		# `Cache` holds internal state that may be accessed often by the user from various
		# commands, but its calculation can be a performance bottleneck, especially when accessed
		# many times in a row. The data should not change frequently.
		# Caching like this is only a last resort and should be avoided.
		# TODO: Invalidate all every 500ms or so, maybe by exposing/wrapping `get` and `set`,
		# because threads can also be long-lived with large loops and sleeps.
		getter cache = ThreadCache.new
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
		@unpause_channel = Channel(Nil).new
		getter paused = false
		getter loop_stack = [] of Cmd::ControlFlow::Loop
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
				@unpause_channel.receive if @paused
				result_channel.send(result)
				result_channel.close
				@result_channel = nil
				result
			end
			result_channel
		end
		def pause
			@paused = true
		end
		def unpause
			return if ! @paused
			@paused = false
			@unpause_channel.send nil
		end
		# returns exit code or nil if this thread isn't done yet
		private def do_next
			cmd = @stack.last?
			if ! cmd
				@done = true
				return @exit_code
			end
			stack_i = @stack.size - 1

			parsed_args = cmd.args.map do |arg|
				Util::AhkString.parse_string(arg, @runner.settings.escape_char) do |var_name_lookup|
					get_var(var_name_lookup)
				end
			end

			{% if ! flag?(:release) %}
				puts "[debug] run: #{cmd.class.name} #{parsed_args.to_s}"
			{% end %}

			begin
				result = cmd.run(self, parsed_args)
			rescue e : RuntimeException
				msg = "Runtime error in line #{cmd.line_no+1}:\n#{e.message}.\n\nThe current thread will exit."
				@runner.display.gui.msgbox msg
				STDERR.puts msg
				@done = true
				@exit_code = 2 # TODO: ???
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
				{% if ! flag?(:release) %}
					puts "[debug] ErrorLevel: #{result}"
				{% end %}
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

		# Get the value of both thread-local and global values,
		# regardless if user set or built-in.
		# Case insensitive
		def get_var(var)
			down = var.downcase
			@runner.get_global_var(down) || @built_in_static_vars[down]? || get_thread_built_in_computed_var(down) || ""
		end
		# `var` is case insensitive
		def set_thread_built_in_static_var(var, value)
			@built_in_static_vars[var.downcase] = value
		end
		# `var` is case sensitive
		private def get_thread_built_in_computed_var(var)
			case var
			when "a_index"
				(@loop_stack.last?.try &.index || 0).to_s
			else
				nil
			end
		end

		def parse_key_combinations(str, *, implicit_braces = false)
			Util::AhkString.parse_key_combinations(str, @runner.settings.escape_char, implicit_braces: implicit_braces)
		end
		def parse_key_combinations_to_charcodemap(str, &block : Array(XDo::LibXDo::Charcodemap), Bool -> _)
			Util::AhkString.parse_key_combinations_to_charcodemap(str, @runner.settings.escape_char, @runner.display.adapter.as(Run::X11), &block) # TODO: type cast etc
		end

		def parse_letter_options(str, &block : Char, Float64? -> _)
			Util::AhkString.parse_letter_options(str, @runner.settings.escape_char, &block)
		end
		def parse_word_options(str)
			Util::AhkString.parse_word_options(str, @runner.settings.escape_char)
		end
	end
end