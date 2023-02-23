# ToolTip [, Text, X, Y, WhichToolTip]
class Cmd::Gtk::Gui::Tooltip < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		id = args[3]?.try &.to_i? || 1
		txt = args[0]?
		x = args[1]?.try &.to_i?
		y = args[2]?.try &.to_i?
		if txt && ! txt.empty?
			thread.runner.display.gui.tooltip(id) do |tooltip|

				# (ahk_x11:655793): Gtk-CRITICAL **: 16:13:19.371: gtk_container_foreach: assertion 'GTK_IS_CONTAINER (container)' failed
				children = tooltip.children
				# Fails every ~50th time, GC something:
				# Nil assertion failed
				begin
					child = children[0]
					lbl = child.unsafe_as(::Gtk::Label)
					lbl.label = txt
				rescue e
					STDERR.puts "Tooltip setting label (Gtk child) failed because of " + e.to_s
				end

				if x && y
					if thread.settings.coord_mode_tooltip == ::Run::CoordMode::RELATIVE
						x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x.not_nil!, y.not_nil!)
					end
					tooltip.move x.not_nil!, y.not_nil!
				end
				tooltip.show_all
			end
		else
			# Updating text is twice as fast than destroying and rebuilding, so maybe hiding
			# would be better here: thread.runner.display.gui.tooltip(id) &.hide
			# However that's not any faster than destroy? So we might as well keep that to
			# clean up unused windows:
			thread.runner.display.gui.destroy_tooltip id
		end
	end
end