class Cmd::X11::Mouse::MouseGetPos < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		x, y, _, window = thread.runner.x_do.mouse_location
		thread.runner.set_user_var(args[0], x.to_s) if args[0]? && ! args[0].empty?
		thread.runner.set_user_var(args[1], y.to_s) if args[1]? && ! args[1].empty?
		thread.runner.set_user_var(args[2], window.window.to_s) if args[2]? && ! args[2].empty?
	end
end