require "./win-util"

class Cmd::X11::Window::WinMaximize < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		Util.match(thread, args, empty_is_last_found: true, a_is_active: true) do |win|
			win.set_state(XDo::StateAction::Add, "maximized_horz")
			win.set_state(XDo::StateAction::Add, "maximized_vert")
		end
	end
end