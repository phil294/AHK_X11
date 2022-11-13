require "../window/win-util"

class Cmd::X11::Mouse::ControlGetText < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var = args[0]
		class_nn_or_text = args[1]? || return
		args.delete_at(0)
		args.delete_at(0)
		Cmd::X11::Window::Util.match(thread, args, empty_is_last_found: true, a_is_active: true) do |win|
			frame = thread.runner.at_spi.find_window(pid: win.pid, window_name: win.name)
			return "1" if ! frame
			acc = thread.runner.at_spi.find_descendant(frame, class_nn_or_text)
			return "1" if ! acc
			txt = thread.runner.at_spi.get_text(acc) || ""
			thread.runner.set_user_var(out_var, txt)
		end
		"0"
	end
end