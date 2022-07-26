require "../base"

class Cmd::ControlFlow::IfWinNotExist < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def self.multi_command; true end
	def self.conditional; true end
	def run(thread, args)
		win = Cmd::X11::Window::Util.match(thread, args, empty_is_last_found: true, a_is_active: false)
		thread.settings.last_found_window = win if win
		! win
	end
end