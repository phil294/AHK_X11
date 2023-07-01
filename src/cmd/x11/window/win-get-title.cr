require "./win-util"
# WinGetTitle, OutputVar [, WinTitle, WinText, ExcludeTitle, ExcludeText]
# This command is also supported on Wayland but it seems the only use case is to get
# top level accessible (aka window) name by ahk_pid. (or in future maybe also ahk_exe / ?)
# fixme: ^ currently not possible because WindowLike.name is not optional but should be (adjust all in win-util.cr)
class Cmd::X11::Window::WinGetTitle < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 5 end
	def run(thread, args)
		match_conditions = args[1..]? || [] of ::String
		out_var = args[0]
		if thread.runner.display.adapter_x11?
			Util.match_win(thread, match_conditions) do |win|
				thread.runner.set_user_var(out_var, win.name || "")
				return
			end
		else
			Util.match_top_level_accessible(thread, match_conditions) do |tl_acc|
				thread.runner.set_user_var(out_var, tl_acc.name)
				return
			end
		end
		thread.runner.set_user_var(out_var, "")
	end
end