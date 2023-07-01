require "./win-util"
# WinKill [, WinTitle, WinText, SecondsToWait, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinKill < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 5 end
	def run(thread, args)
		match_conditions = args
		match_conditions.delete_at(2) if args.size >= 3
		if thread.runner.display.adapter_x11?
			Util.match_win(thread, match_conditions) do |win|
				win.kill!
			end
		else
			Util.match_top_level_accessible(thread, match_conditions) do |tl_acc|
				Process.signal(Signal::INT, tl_acc.process_id)
				sleep 5.millisecond
				Process.signal(Signal::KILL, tl_acc.process_id)
			end
		end
	end
end