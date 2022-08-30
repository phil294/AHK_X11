class Cmd::X11::Mouse::MouseClick < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def run(thread, args)
		# TODO: this is just quickly hacked together, implement proper mouse commands
		thread.runner.x11.pause do
			_, _, screen = thread.runner.x_do.mouse_location
			thread.runner.x_do.move_mouse (args[1]?.try &.to_i? || 0), (args[2]?.try &.to_i? || 0), screen
			thread.runner.x_do.click XDo::Button::Left
		end
	end
end