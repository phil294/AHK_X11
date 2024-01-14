require "./hotkey-definition"

module Run
	class Hotkey < HotkeyDefinition
		property cmd : Cmd::Base?
		getter keysym : UInt64
		property active = true
		property exempt_from_suspension = false
		@threads = [] of Thread
		def initialize(key_str, *, label, key_combo, @cmd, @keysym, priority, max_threads, @active = true)
			super(key_str, label, key_combo, priority, max_threads)
			init
		end
		# TODO why @ for priority and max_threads here?
		def initialize(definition, *, @cmd, @keysym, @priority, @max_threads, @active = true)
			super(definition.key_str, definition, priority: @priority, max_threads: @max_threads)
			init
		end
		private def init
			@exempt_from_suspension = @cmd.is_a?(Cmd::Misc::Suspend)
		end

		def trigger(runner)
			@threads.reject! &.done
			# TODO: (commands not implemented yet):
			# && ! @cmd_is_a?(Cmd::KeyHistory) && ! @cmd_is_a?(Cmd::ListLines) && ! @cmd_is_a?(Cmd::ListVars) && ! @cmd_is_a?(ListHotkeys)
			if @threads.size >= @max_threads && ! @cmd.is_a?(Cmd::ControlFlow::ExitApp) && ! @cmd.is_a?(Cmd::Misc::Pause) && ! @cmd.is_a?(Cmd::Gtk::Edit) && ! @cmd.is_a?(Cmd::Misc::Reload)
				# TODO: logger warn? what does win ahk do?
				STDERR.puts "WARN: Skipping thread for hotkey press '#{key_str}' because #{@threads.size} threads are already running (max_threads==#{@max_threads}"
				return
			end
			thread = runner.not_nil!.add_thread @cmd.not_nil!, @key_str, @priority, hotkey: self
			@threads << thread
		end
	end
end