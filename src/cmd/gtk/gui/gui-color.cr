# Color [, WindowColor, ControlColor]
class Cmd::Gtk::Gui::GuiColor < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def run(thread, args)
		gui_id = args[0]
		thread.runner.display.gui.gui(thread, gui_id) do |gui|
			if args[1]? && ! args[1].empty?
				window_color = thread.runner.display.gui.parse_rgba(args[1])
				gui.window.override_background_color(::Gtk::StateFlags::NORMAL, window_color)
				gui.window_color = window_color
			end
			if args[2]? && ! args[2].empty?
				gui.control_color = thread.runner.display.gui.parse_rgba(args[2])
			end
		end
	end
end