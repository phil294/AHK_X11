class Cmd::Gtk::Gui::Tooltip < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		id = args[3]?.try &.to_i? || 1
		txt = args[0]?
		x = args[1]?.try &.to_i?
		y = args[2]?.try &.to_i?
		thread.runner.display.gui.tooltip(id) do |tooltip|
			if txt
				tooltip.children.next.unsafe_as(::Gtk::Label).label = txt
				if x && y
					if thread.settings.coord_mode_tooltip == ::Run::CoordMode::RELATIVE
						x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x.not_nil!, y.not_nil!)
					end
					tooltip.move x.not_nil!, y.not_nil!
				end
				tooltip.show_all
			else
				tooltip.destroy
			end
		end
	end
end