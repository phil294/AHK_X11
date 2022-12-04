require "./win-util"

class Cmd::X11::Window::WinGet < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def run(thread, args)
		match_conditions = args[2..]? || [] of ::String
		out_var = args[0]
		cmd = args[1]? || "id"
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			value = case cmd.downcase
			when "id"
				win.window
			when "controllist"
				ctrls = [] of ::String
				# skip non interactive: Not quite by spec, but when using this command, you usually
				# only want interactive ones, and filtering out non-interactives with AHK code is
				# either very hard or very slow, specially given our current line execution speed...
				# But it does add a little bit of incompatibility with Windows
				thread.runner.display.at_spi.each_descendant(thread, win, max_children: 1000, skip_non_interactive: true) do |_, _, class_NN|
					ctrls << class_NN
					true
				end
				ctrls.join '\n'
			end
			thread.runner.set_user_var(out_var, value.to_s)
		end
	end
end