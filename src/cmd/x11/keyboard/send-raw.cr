class Cmd::X11::Keyboard::SendRaw < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.x11.pause do # to prevent hotkey from triggering other hotkey or itself
			modifiers_before = thread.runner.x_do.active_modifiers
			thread.runner.x_do.clear_active_modifiers modifiers_before
			thread.runner.x_do.type args[0]
			thread.runner.x_do.set_active_modifiers modifiers_before
		end
	end
end