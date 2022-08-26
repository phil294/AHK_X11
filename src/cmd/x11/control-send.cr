# INCOMPAT: control arg ignored
# INCOMPAT: This may *sometimes* not work, as some windows seem to ignore the events sent. This problem is probably not fixable. Doing `WinActivate` and `Send` instead should always work.
class Cmd::X11::ControlSend < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		_control, keys, *match_conditions = args
		Cmd::X11::Window::Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			thread.runner.x11.pause do
				thread.parse_keys(keys) do |key_map, pressed|
					win.keys_raw key_map, pressed: pressed, delay: 0
				end
			end
		end
	end
end