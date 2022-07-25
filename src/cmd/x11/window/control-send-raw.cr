require "../../base"
require "./win-util"

# INCOMPAT: control arg ignored
# INCOMPAT: This may *sometimes* not work, as some windows seem to ignore the events sent. This problem is present as well in `xdotool`, the underlying automation library. It may not be fixable. Doing `WinActivate` and `Send` instead should always work.
class Cmd::Window::ControlSendRaw < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		_control, keys, *match_conditions = args
		win = Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true)
		return if ! win
		thread.runner.pause_x11
		win.type keys
		thread.runner.resume_x11
	end
end