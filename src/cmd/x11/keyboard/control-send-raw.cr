class Cmd::X11::Keyboard::ControlSendRaw < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		_control, keys, *match_conditions = args
		Cmd::X11::Window::Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			thread.runner.x11.pause do
				win.clear_active_modifiers thread.runner.x_do.active_modifiers
				win.type keys
			end
		end
	end
end