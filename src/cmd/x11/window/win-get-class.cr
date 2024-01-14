require "./win-util"
# WinGetClass, OutputVar [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinGetClass < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 5 end
	def run(thread, args)
		match_conditions = args[1..]? || [] of ::String
		out_var = args[0]
		Util.match_win(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			# We seem to actually get class here, not class_name
			thread.runner.set_user_var(out_var, win.class_name || "")
			return
		end
		thread.runner.set_user_var(out_var, "")
	end
end