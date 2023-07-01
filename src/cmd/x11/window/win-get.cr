require "./win-util"
# WinGet, OutputVar [, Cmd, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinGet < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def run(thread, args)
		match_conditions = args[2..]? || [] of ::String
		out_var = args[0]
		cmd = args[1]? || "id"
		value = case cmd.downcase
		when "id"
			v = nil
			# fixme: most of the checks for adapter_x11 in the codebase should pbly display.x11? instead as adapter can be overwritten with #inputdevice
			# todo: also maybe rename .x11? to x11_server_running? or sth
			if thread.runner.display.adapter_x11?
				Util.match_win(thread, match_conditions) do |win|
					v = win.window
				end
			else
				Util.match_top_level_accessible(thread, match_conditions) do |tl_acc|
					v = tl_acc.hash
					thread.cache.top_level_accessible_by_hash[v] = tl_acc
				end
			end
			v
		when "controllist"
			ctrls = [] of ::String
			Util.match_top_level_accessible(thread, match_conditions) do |tl_acc|
				# skip non interactive: Not quite by spec, but when using this command, you usually
				# only want interactive ones, and filtering out non-interactives with AHK code is
				# either very hard or very slow, specially given our current line execution speed...
				# But it does add a little bit of incompatibility with Windows
				thread.runner.display.at_spi &.each_descendant_of_top_level_accessible(thread, tl_acc, max_children: 1000, skip_non_interactive: true) do |_, _, class_NN|
					ctrls << class_NN
					true
				end
			end
			ctrls.join '\n'
		end
		thread.runner.set_user_var(out_var, value.to_s)
	end
end