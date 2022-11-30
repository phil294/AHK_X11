class Cmd::X11::Mouse::MouseGetPos < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		x, y, _, window = thread.runner.display.x_do.mouse_location
		if args[3]? && ! args[3].empty?
			_, class_NN = thread.runner.display.at_spi.find_descendant(thread, window, x: x, y: y)
			if class_NN
				thread.runner.set_user_var(args[3], class_NN)
			else
				thread.runner.set_user_var(args[3], "")
			end
		end
		if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
			x, y = Cmd::X11::Window::Util.coord_screen_to_relative(thread, x, y)
		end
		thread.runner.set_user_var(args[0], x.to_s) if args[0]? && ! args[0].empty?
		thread.runner.set_user_var(args[1], y.to_s) if args[1]? && ! args[1].empty?
		thread.runner.set_user_var(args[2], window.window.to_s) if args[2]? && ! args[2].empty?
	end
end