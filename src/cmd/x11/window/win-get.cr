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
			end
			thread.runner.set_user_var(out_var, value.to_s)
		end
	end
end