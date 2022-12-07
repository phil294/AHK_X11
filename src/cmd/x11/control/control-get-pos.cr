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
			ext = thread.runner.display.at_spi do |at_spi|
				acc = at_spi.find_descendant(thread, win, class_nn_or_text)
				if acc
					at_spi.get_pos(thread, win, acc)
				end
			end
			return if ! ext
			thread.runner.set_user_var(out_x, ext[0].to_s) if out_x && ! out_x.empty?
			thread.runner.set_user_var(out_y, ext[1].to_s) if out_y && ! out_y.empty?
			thread.runner.set_user_var(out_w, ext[2].to_s) if out_w && ! out_w.empty?
			thread.runner.set_user_var(out_h, ext[3].to_s) if out_h && ! out_h.empty?
		end
	end
end