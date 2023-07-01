require "./hotkey-definition"

module Run
	class Hotkey < HotkeyDefinition
		property cmd : Cmd::Base?
		getter keysym : UInt64
		property active = true
		property exempt_from_suspension = false
		def initialize(key_str, label, key_combo, @cmd, @keysym, priority, @active = true)
			super(key_str, label, key_combo, priority)
			init
		end
		def initialize(definition, @cmd, @keysym, @priority, @active = true)
			super(definition.key_str, definition, priority: @priority)
			init
		end
		private def init
			@exempt_from_suspension = @cmd.is_a?(Cmd::Misc::Suspend)
		end

		def trigger(runner)
			runner.not_nil!.add_thread @cmd.not_nil!, @priority
		end
	end
end