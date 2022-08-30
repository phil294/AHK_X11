class Cmd::ControlFlow::IfWinNotActive < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def self.multi_command; true end
	def self.conditional; true end
	def run(thread, args)
		active = false
		Cmd::X11::Window::Util.match(thread, args, empty_is_last_found: true, a_is_active: false) do |win|
			active = win == thread.runner.x_do.active_window
		end
		! active
	end
end