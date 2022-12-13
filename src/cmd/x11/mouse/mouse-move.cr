class Cmd::X11::Mouse::MouseMove < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		x_current, y_current, screen = thread.runner.display.x_do.mouse_location
		x = args[0]?.try &.to_i? || x_current
		y = args[1]?.try &.to_i? || y_current
		relative = args[3]?.try &.downcase == "r"
		thread.runner.display.pause do
			if relative
				thread.runner.display.x_do.move_mouse x, y
			else
				if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
					x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x, y)
				end
				thread.runner.display.x_do.move_mouse x, y, screen
			end
		end
	end
end