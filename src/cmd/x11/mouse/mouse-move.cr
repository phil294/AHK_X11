class Cmd::X11::Mouse::MouseMove < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		x_current, y_current, screen = thread.runner.x_do.mouse_location
		x = args[0]?.try &.to_i? || x_current
		y = args[1]?.try &.to_i? || y_current
		relative = args[3]?.try &.downcase == "r"
		thread.runner.x11.pause do
			if relative
				thread.runner.x_do.move_mouse x, y
			else
				thread.runner.x_do.move_mouse x, y, screen
			end
		end
	end
end