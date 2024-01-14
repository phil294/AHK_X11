require "./win-util"
# WinClose [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinShow < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		match_conditions = args
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true, force_detect_hidden_windows: true) do |win|
			win.map!
		end
	end
end