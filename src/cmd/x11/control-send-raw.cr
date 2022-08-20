# INCOMPAT: control arg ignored
# INCOMPAT: This may *sometimes* not work, as some windows seem to ignore the events sent. This problem is probably not fixable. Doing `WinActivate` and `Send` instead should always work.
class Cmd::X11::ControlSendRaw < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		_control, keys, *match_conditions = args
		win = Cmd::X11::Window::Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true)
		return if ! win
		thread.runner.x11.pause
		win.type keys
		thread.runner.x11.resume
	end
end