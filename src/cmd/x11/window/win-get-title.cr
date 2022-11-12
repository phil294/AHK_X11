require "./win-util"

class Cmd::X11::Window::WinGetTitle < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 5 end
	def run(thread, args)
		match_conditions = args[1..]? || [] of ::String
		out_var = args[0]
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			thread.runner.set_user_var(out_var, win.name || "")
			return
		end
		thread.runner.set_user_var(out_var, "")
	end
end