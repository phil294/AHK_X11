require "./win-util"
# WinSetTitle, NewTitle
# WinSetTitle, WinTitle, WinText, NewTitle [, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinSetTitle < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 5 end
	def run(thread, args)
		if args.size == 1
			new_title = args[0]
			match_conditions = [] of ::String
		else
			new_title = args[2]? || ""
			match_conditions = args[0..]
			match_conditions.delete_at(2) if match_conditions[2]?
		end
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			win["WM_NAME"] = new_title
		end
	end
end