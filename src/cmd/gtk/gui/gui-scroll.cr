# AHK_X11-only
# GuiScroll [, Index]
class Cmd::Gtk::Gui::GuiScroll < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread, args)
		gui_id = args[0]
		name_or_index = args[1]? && args[1].downcase
		thread.runner.display.gtk.gui(thread, gui_id) do |gui|
			if ! name_or_index
				gui.active_scroll_area = nil
			else
				gui.active_scroll_area = gui.scroll_areas[name_or_index.to_i - 1]
			end
			gui.last_x = 0
			gui.last_y = 0
		end
	end
end