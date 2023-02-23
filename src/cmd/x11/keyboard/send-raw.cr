# SendRaw, Keys
class Cmd::X11::Keyboard::SendRaw < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.display.pause do # to prevent hotkey from triggering other hotkey or itself
			thread.runner.display.x_do.clear_active_modifiers thread.runner.display.x_do.active_modifiers
			thread.runner.display.x_do.type args[0]
		end
	end
end