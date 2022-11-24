require "../window/win-util"

class Cmd::X11::Mouse::ControlGetPos < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 9 end
	def run(thread, args)
		out_x = args[0]?
		out_y = args[1]?
		out_w = args[2]?
		out_h = args[3]?
		class_nn_or_text = args[4]? || return
		5.times do
			args.delete_at(0)
		end
		Cmd::X11::Window::Util.match(thread, args, empty_is_last_found: true, a_is_active: true) do |win|
			frame = thread.runner.display.at_spi.find_window(pid: win.pid, window_name: win.name)
			return if ! frame
			acc = thread.runner.display.at_spi.find_descendant(frame, class_nn_or_text)
			return if ! acc
			ext = acc.extents(::Atspi::CoordType::WINDOW)
			thread.runner.set_user_var(out_x, ext.x.to_s) if out_x && ! out_x.empty?
			thread.runner.set_user_var(out_y, ext.y.to_s) if out_y && ! out_y.empty?
			thread.runner.set_user_var(out_w, ext.width.to_s) if out_w && ! out_w.empty?
			thread.runner.set_user_var(out_h, ext.height.to_s) if out_h && ! out_h.empty?
		end
	end
end