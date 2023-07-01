# MouseMove, X, Y [, Speed, R]
class Cmd::X11::Mouse::MouseMove < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		x = args[0]?.try &.to_i?
		y = args[1]?.try &.to_i?
		relative = args[3]?.try &.downcase == "r"
		thread.runner.display.pause do
			thread.runner.display.adapter.mouse_move thread, x, y, relative
		end
	end
end