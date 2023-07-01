require "./win-util"
# WinMaximize [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinMaximize < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		Util.match_win(thread, args) do |win|
			win.set_state(XDo::WindowStateAction::Add, "maximized_horz")
			win.set_state(XDo::WindowStateAction::Add, "maximized_vert")
		end
	end
end