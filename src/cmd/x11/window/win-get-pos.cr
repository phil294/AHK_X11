require "./win-util"

class Cmd::X11::Window::WinGetPos < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 8 end
	def run(thread, args)
		match_conditions = args[4..]? || [] of ::String
		out_x = args[0]?
		out_y = args[1]?
		out_w = args[2]?
		out_h = args[3]?
		found = Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			x, y = win.location
			w, h = win.size
			thread.runner.set_user_var(out_x, x.to_s) if out_x
			thread.runner.set_user_var(out_y, y.to_s) if out_y
			thread.runner.set_user_var(out_w, w.to_s) if out_w
			thread.runner.set_user_var(out_h, h.to_s) if out_h
		end
		if ! found
			thread.runner.set_user_var(out_x, "") if out_x
			thread.runner.set_user_var(out_y, "") if out_y
			thread.runner.set_user_var(out_w, "") if out_w
			thread.runner.set_user_var(out_h, "") if out_h
		end
	end
end