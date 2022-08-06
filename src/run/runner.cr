require "./thread"
require "./timer"
require "./hotkey"
require "../cmd/base"
require "./gui"
require "./x11"
require "x_do"

module Run
	# see `Thread.settings` for scope explanation.
	# Some RunnerSettings are constant (never changed) because they are set in parser only.
	struct RunnerSettings
		property persistent = false
		property escape_char = '`'
		# INCOMPAT: Pressing return is a \r, not sure if \n even ever fires
		property hotstring_end_chars = ['-', '(', ')', '[', ']', '{', '}', ':', ';', '\'', '"', '/', '\\', ',', '.', '?', '!', '\n', ' ', '\t', '\r']
	end

	# can start a completely fresh and isolated ahk execution instance with its own
	# variables etc. All properties can and will be heavily accessed from outside (commands).
	# Currently however, there's only ever one single runner instance and there's no real reason
	# why multiple should be needed, but it still makes sense to encapsulate appropriately.
	#
	# All Runner state (vars, labels, etc.) is global (cross-thread).
	class Runner
		# These are editable by the user
		@user_vars = {} of String => String
		# These are only changed by the program. See also `get_global_built_in_computed_var`
		@built_in_static_vars = {
			"a_space" => " ",
			"a_index" => "0",
			"a_workingdir" => Dir.current,
			"a_endchar" => ""
		}
		protected getter labels : Hash(String, Cmd::Base)
		@threads = [] of Thread
		@auto_execute_thread : Thread?
		@run_thread_channel = Channel(Nil).new
		@exit_code = 0
		@timers = {} of String => Timer
		# see Thread.settings
		@default_thread_settings = ThreadSettings.new
		@hotkeys = {} of String => Hotkey
		@hotstrings = [] of Hotstring
		getter x11 = X11.new
		getter x_do = XDo.new
		getter gui = Gui.new
		# similar to `ThreadSettings`
		getter settings : RunnerSettings

		def initialize(*, @labels, escape_char, @settings)
			@settings.escape_char = escape_char
		end
		def run(*, hotkeys, hotstrings, auto_execute_section : Cmd::Base)
			hotkeys.each { |h| add_hotkey h }
			hotstrings.each { |h| add_hotstring h }
			spawn @x11.run self, @settings.hotstring_end_chars # separate worker thread because event loop is blocking
			spawn @gui.run # separate worker thread because gtk loop is blocking
			spawn same_thread: true { clock }
			@auto_execute_thread = add_thread auto_execute_section, 0
		end

		# add to the thread queue. Depending on priority and `@threads`, it may be picked up
		# by the clock fiber immediately afterwards
		protected def add_thread(cmd, priority) : Thread
			thread = Thread.new(self, cmd, priority, @default_thread_settings)
			i = @threads.index { |t| t.priority > thread.priority } || @threads.size
			@threads.insert(i, thread)
			@run_thread_channel.send(nil) if i == @threads.size - 1
			thread
		end

		# Forever continuously figures out the "current thread" (`@threads.last`) and
		# runs one command after another. Commands are only ever called synchronously
		# from a single thread, never multiple handled at the same time. However, a long
		# running command (e.g. `sleep, 10000`) may run until its end in the background while
		# another thread takes the lead.
		#
		# There must only be one instance of this running.
		private def clock
			loop do
				while thread = @threads.last?
					select
					when @run_thread_channel.receive
						# current command may finish in the background, but its result handling and thread continuation
						# will have to wait: probably because another, more important thread came along which will now
						# get attention in the next iteration
					when exit_code = thread.next.receive?
						if ! exit_code.nil?
							@exit_code = exit_code
							@threads.pop
							if thread == @auto_execute_thread
								@default_thread_settings = thread.settings
								exit_app @exit_code if ! @settings.persistent && @hotkeys.empty? && @hotstrings.empty?
							end
						end
					end
				end
				# all done, now wait for something new to do
				@run_thread_channel.receive
			end
		end

		def exit_app(code)
			::exit code
		end

		# Do not use directly, use `Thread.get_var` instead.
		# Get the value of global values, regardless if user set or not.
		# Case sensitive.
		def get_global_var(var)
			@user_vars[var]? || @built_in_static_vars[var]? || get_global_built_in_computed_var(var)
		end
		# Case insensitive
		def get_user_var(var)
			@user_vars[var.downcase]? || ""
		end
		def print_user_vars # TODO is that true / ListVars shouldnt print builtins / threadlocals like errorlevel?
			puts @user_vars
		end
		# `var` is case insensitive
		def set_user_var(var, value)
			down = var.downcase
			return if @built_in_static_vars[down]? || get_global_built_in_computed_var(down)
			@user_vars[down] = value
		end
		# `var` is case insensitive
		def set_global_built_in_static_var(var, value)
			@built_in_static_vars[var.downcase] = value
		end
		# `var` is case insensitive
		private def get_global_built_in_computed_var(var)
			case var.downcase
			when "a_now"
				"123" # TODO
			else
				nil
			end
		end
		
		def get_timer(label)
			@timers[label]?
		end
		def add_timer(label, period, priority)
			cmd = labels[label]?
			raise RuntimeException.new "add timer: label '#{label}' not found" if ! cmd
			timer = Timer.new(self, cmd, period, priority)
			@timers[label] = timer
			timer
		end

		def add_hotkey(hotkey)
			hotkey.runner = self
			hotkey.set_keysym
			hotkey.cmd = labels[hotkey.key_str]
			@hotkeys[hotkey.key_str] = hotkey
			@x11.register_hotkey hotkey
			hotkey
		end
		def add_or_update_hotkey(*, key_str, label, priority, active_state = nil)
			if label
				cmd = labels[label]?
				raise RuntimeException.new "Add or update Hotkey: Label '#{label}' not found" if ! cmd
			end
			hotkey = @hotkeys[key_str]?
			if hotkey
				@x11.unregister_hotkey hotkey
				active_state = hotkey.active if active_state.nil?
			else
				raise RuntimeException.new "Nonexistent Hotkey.\n\nSpecifically: #{key_str}" if ! label
				hotkey = Hotkey.new(self, cmd.not_nil!, key_str, priority: priority)
				@hotkeys[hotkey.key_str] = hotkey
				active_state = true if active_state.nil?
			end
			hotkey.cmd = cmd if cmd
			hotkey.priority = priority if priority
			if active_state
				@x11.register_hotkey hotkey
				hotkey.active = true
			else
				hotkey.active = false
			end
			hotkey
		end

		def add_hotstring(hotstring)
			hotstring.runner = self
			hotstring.cmd = labels[hotstring.label]
			@hotstrings << hotstring
			@x11.register_hotstring hotstring
			hotstring
		end
	end

	class RuntimeException < Exception end
end