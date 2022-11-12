require "./win-util"

class Cmd::X11::Window::WinGetText < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 5 end
	def self.sets_error_level; true end
	def run(thread, args)
		match_conditions = args[1..]? || [] of ::String
		out_var = args[0]
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			frame = thread.runner.at_spi.find_window(pid: win.pid, window_name: win.name)
			if frame
				texts = thread.runner.at_spi.get_all_texts(frame, include_hidden: false)
				thread.runner.set_user_var(out_var, texts.join("\n"))
				return "0"
			end
		end
		thread.runner.set_user_var(out_var, "")
		"1"
	end
end