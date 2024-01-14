require "./win-util"
# WinGet, OutputVar [, Cmd, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinGet < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def run(thread, args)
		match_conditions = args[2..]? || [] of ::String
		out_var = args[0]
		cmd = (args[1]? || "id").downcase
		case cmd
		when "count", "list"
			win_likes = Util.match_win_likes(thread, match_conditions, empty_is_last_found: true, a_is_active: true)
			case cmd
			when "count"
				thread.runner.set_user_var(out_var, win_likes.size.to_s)
			when "list"
				thread.runner.set_user_var(out_var, win_likes.size.to_s)
				win_likes.each_with_index do |win, i|
					thread.runner.set_user_var("#{out_var}#{i + 1}", win.id.to_s)
				end
			end
		when "controllist"
			ctrls = [] of ::String
			Util.match_top_level_accessible(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |tl_acc|
				# skip non interactive: Not quite by spec, but when using this command, you usually
				# only want interactive ones, and filtering out non-interactives with AHK code is
				# either very hard or very slow, specially given our current line execution speed...
				# But it does add a little bit of incompatibility with Windows
				thread.runner.display.at_spi &.each_descendant_of_top_level_accessible(thread, tl_acc, max_children: 1000, skip_non_interactive: true) do |_, _, class_NN|
					ctrls << class_NN
					true
				end
			end
			value = ctrls.join '\n'
			thread.runner.set_user_var(out_var, value)
		else
			win_like = Util.match_window_like(thread, match_conditions, empty_is_last_found: true, a_is_active: true)
			value = case cmd
			when "id"
				v.id
			when "pid"
				v.pid
			when "processname"
				`ps -p #{win.pid} -o comm=`
			end
			thread.runner.set_user_var(out_var, value.to_s)
		end
	end
end