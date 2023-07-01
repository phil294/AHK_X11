require "./win-util"
# WinClose [, WinTitle, WinText, SecondsToWait, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinClose < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 5 end
	def run(thread, args)
		match_conditions = args
		match_conditions.delete_at(2) if args.size >= 3
		# todo docs evdev: use winkill or processkill(?) instead
		Util.match_win(thread, match_conditions) do |win|
			win.quit!
		end
	end
end