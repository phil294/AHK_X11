# ControlSend [, Control, Keys, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Keyboard::ControlSend < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		_control, keys, *match_conditions = args
		Cmd::X11::Window::Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			thread.runner.display.pause do
				win.clear_active_modifiers thread.runner.display.x_do.active_modifiers
				thread.parse_key_combinations_to_charcodemap(keys) do |key_map, pressed|
					win.keys_raw key_map, pressed: pressed, delay: 0
				end
			end
		end
	end
end