require "./win-util"
# WinMinimizeAllUndo
class Cmd::X11::Window::WinMinimizeAllUndo < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread, args)
		thread.runner.display.adapter.show_desktop(false)
	end
end