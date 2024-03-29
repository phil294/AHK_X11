require "./win-util"
# WinMinimize [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinMinimize < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		Util.match(thread, args, empty_is_last_found: true, a_is_active: true) do |win|
			win.minimize!
		end
	end
end