require "./win-util"
# WinHide [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinHide < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		match_conditions = args
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			win.unmap!
		end
	end
end