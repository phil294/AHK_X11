require "./thread"
require "./timer"
require "./hotkey"
require "../cmd/base"

module Run
	enum SingleInstance
		Prompt
		Force
		Ignore
		Off
	end

	# see `Thread.settings` for scope explanation.
	# Some RunnerSettings are constant (never changed) because they are set in parser only.
	struct RunnerSettings
		property persistent = false
		property escape_char = '`'
		property hotstring_end_chars = ['-', '(', ')', '[', ']', '{', '}', ':', ';', '\'', '"', '/', '\\', ',', '.', '?', '!', '\n', ' ', '\t', '\r']
		property single_instance : SingleInstance?
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
			"a_tab" => "\t",
			"a_workingdir" => Dir.current,
			"a_endchar" => "",
			"a_iconfile" => "",
			"a_icontip" => "",
			"a_home" => Path.home.to_s,
			"a_scriptdir" => "",
			"a_scriptname" => "",
			"a_scriptfullpath" => "",
			"a_ahkversion" => "1.0.24",
			"a_ostype" => "Linux",
		}
		@initial_working_dir = Dir.current
		protected getter labels : Hash(String, Cmd::Base)
		@threads = [] of Thread
		@auto_execute_thread : Thread?
		@run_thread_channel = Channel(Nil).new
		@exit_code = 0
		@timers = {} of String => Timer
		# see Thread.settings
		@default_thread_settings = ThreadSettings.new
		# similar to `ThreadSettings`
		getter settings : RunnerSettings
		property current_input_channel : Channel(String)?
		@builder : Build::Builder
		getter script_file : Path?
		getter headless : Bool
		@display : Display?
		def display
			raise "Cannot access Display in headless mode" if @headless
			@display.not_nil!
		end

		def initialize(*, @builder, @script_file, @headless)
			@labels = @builder.labels
			@settings = @builder.runner_settings
			script = @script_file ? @script_file.not_nil! : Path[Process.executable_path || ""].expand
			set_global_built_in_static_var "A_ScriptDir", script.dirname
			set_global_built_in_static_var "A_ScriptName", script.basename
			set_global_built_in_static_var "A_ScriptFullPath", script.to_s
		end
		def run
			@settings.persistent ||= (! @builder.hotkeys.empty? || ! @builder.hotstrings.empty?)
			if ! @headless
				@display = Display.new self
				@display.not_nil!.run hotstrings: @builder.hotstrings, hotkeys: @builder.hotkeys
				if ! @settings.single_instance
					@settings.single_instance = @settings.persistent ? SingleInstance::Prompt : SingleInstance::Off
				end
				handle_single_instance
			end
			Fiber.yield
			spawn same_thread: true { clock }
			if (auto_execute_section = @builder.start)
				@auto_execute_thread = add_thread auto_execute_section, 0
			else
				auto_execute_section_ended
			end
		end

		# add to the thread queue. Depending on priority and `@threads`, it may be picked up
		# by the clock fiber immediately afterwards
		def add_thread(cmd : Cmd::Base | String, priority) : Thread
			if cmd.is_a?(String)
				cmd_ = @labels[cmd]?
				raise RuntimeException.new "Label '#{cmd}' not found" if ! cmd_
				cmd = cmd_
			end
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
					if ! @headless
						if thread.paused
							display.gui.thread_pause
						else
							display.gui.thread_unpause
						end
					end
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
								auto_execute_section_ended
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

		def reload
			STDERR.puts "Reloading..."
			bin_path = Process.executable_path
			raise RuntimeException.new "Cannot determine binary path" if ! bin_path
			p = Process.new bin_path, ARGV, chdir: @initial_working_dir
			exit_app 0
		end

		private def auto_execute_section_ended
			exit_app @exit_code if ! @settings.persistent
			repl
		end
		private def repl
			spawn do
				puts "Interactive AHK_X11 console (REPL). Type any command. Multi-line text not supported. Press {CTRL}+C to exit."
				loop do
					print "ahk_x11> "
					begin
						line = read_line
					rescue e
						break # i.e. there is no stdin, it was closed or never existed like when run via double click.
					end
					begin
						@builder.build [line]
						add_thread @builder.start.not_nil!, 0 if @builder.start
						Fiber.yield
					rescue e
						STDERR.puts e.message
					end
				end
			end
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
			case down
			when "clipboard"
				display.gui.clipboard do |clip|
					clip.set_text(value, -1)
					clip.store
				end
			else
				return if @built_in_static_vars[down]? || get_global_built_in_computed_var(down)
				{% if ! flag?(:release) %}
					puts "[debug] set_user_var '#{var}': #{value}"
				{% end %}
				@user_vars[down] = value
			end
		end
		# `var` is case insensitive
		def set_global_built_in_static_var(var, value)
			@built_in_static_vars[var.downcase] = value
		end
		# `var` is case insensitive
		private def get_global_built_in_computed_var(var)
			case var.downcase
			when "a_yyyy", "a_year" then Time.local.year.to_s
			when "a_mm", "a_mon" then Time.local.month.to_s(precision: 2)
			when "a_dd", "a_mday" then Time.local.day.to_s(precision: 2)
			when "a_wday" then (Time.local.day_of_week.value % 7 + 1).to_s
			when "a_yday" then Time.local.day_of_year.to_s
			when "a_yweek"
				year, week = Time.local.calendar_week
				"#{year}#{week}"
			when "a_hour" then Time.local.hour.to_s(precision: 2)
			when "a_min" then Time.local.minute.to_s(precision: 2)
			when "a_sec" then Time.local.second.to_s(precision: 2)
			when "a_now" then Time.local.to_YYYYMMDDHH24MISS
			when "a_nowutc" then Time.utc.to_s("%Y%m%d%H%M%S")
			when "a_tickcount" then Time.monotonic.total_milliseconds.round.to_i.to_s
			when "clipboard"
				display.gui.clipboard &.wait_for_text
			else
				nil
			end
		end

		def get_timer(label)
			@timers[label]?
		end
		def add_timer(label, period, priority)
			cmd = @labels[label]?
			raise RuntimeException.new "add timer: label '#{label}' not found" if ! cmd
			timer = Timer.new(self, cmd, period, priority)
			@timers[label] = timer
			timer
		end

		def handle_single_instance
			return if @settings.single_instance == SingleInstance::Off
			search_for = (PROGRAM_NAME + " " + ARGV.join(" ")).strip
			result = IO::Memory.new
			begin
				Process.run("pgrep", ["--full", "--exact", search_for], output: result)
			rescue e : IO::Error
				STDERR.puts "Warning: Could not determine previously running instance because pgrep is not installed. Using SingleInstance OFF."
				return
			end
			already_running = result.to_s.chomp
				.split('\n')
				.select{|p| p != Process.pid.to_s }
				.first?.try &.to_i?
			return if ! already_running
			case @settings.single_instance
			when SingleInstance::Force
				Process.signal(Signal::HUP, already_running)
			when SingleInstance::Ignore
				STDERR.puts "Instance already running and #SingleInstance Ignore passed. Exiting."
				::exit
			when SingleInstance::Prompt
				response = display.gui.msgbox "An older instance of this script is already running. Replace it with this instance?\nNote: To avoid this message, see #SingleInstance in the help file.", options: 4
				::exit if response != Gui::MsgBoxButton::Yes
				Process.signal(Signal::HUP, already_running)
			end
		end

		@suspension = false
		def suspend(mode = nil)
			mode = ! @suspension if mode == nil
			@suspension = mode.as(Bool)
			if mode
				display.suspend
				display.gui.suspend
			else
				display.unsuspend
				display.gui.unsuspend
			end
		end
		def pause_thread(mode = nil, *, self_is_thread = true)
			underlying_thread = @threads[@threads.size - (self_is_thread ? 2 : 1)]?
			if mode == nil
				mode = ! underlying_thread || ! underlying_thread.paused
			end
			if mode
				if underlying_thread
					underlying_thread.pause
					display.gui.thread_pause if ! @headless
				end
			else
				underlying_thread.unpause if underlying_thread
			end
		end
	end

	class RuntimeException < Exception end
end