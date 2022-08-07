require "../../base"

class Cmd::Gtk::Gui::GuiAdd < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		gui_id = args[0]
		type = args[1]
		options = args[2]? || ""
		text = args[3]? || ""
		thread.runner.gui.gui(gui_id) do |gui|
			opt = thread.parse_word_options options
			widget : ::Gtk::Widget? = nil
			case type.downcase
			when "text"
				widget = ::Gtk::Label.new text
			else
				raise Run::RuntimeException.new "Unknown Gui control '#{type}'"
			end

			gui.padding = 7 if gui.padding == 0 # TODO:

			# Positioning based on previous control:
			# Based on previous x/y is possible, but not based on w/h, as that isn't available before
			# the controls have been shown I think: https://stackoverflow.com/questions/2675514/totally-fed-up-with-get-gtk-widget-height-and-width#comment129395027_2676987z
			# Until a solution is found here (TODO:) (perhaps using manual width calculation
			# (gtk api for text width calc?)), consequently `X+n` and `wp+n` is not possible and the
			# code for it is deactivated below for X and removed for others.
			#
			# if last_widget = gui.last_widget
			# 	last_w = last_widget.allocated_width # or maybe it's `.allocation`, idk, both don't work without a previous `show_all` and waiting
			# 	last_h = last_widget.allocated_height
			# else
			# 	last_w = last_h = 0
			# end
			x = case
			when opt["x"]?
				x_ = opt["x"][:n] || 0
				# x_ += gui.last_x + last_w if opt["x"][:plus]
				# x_ = gui.last_x + last_w - x_ if opt["x"][:minus]
				x_
			when opt["xp"]?
				gui.last_x + (opt["xp"][:n] || 0) * (opt["xp"][:minus] ? -1 : 1)
			when opt["xm"]?
				gui.padding + (opt["xm"][:n] || 0) * (opt["xm"][:minus] ? -1 : 1)
			when opt["xs"]?
				gui.last_section_x + (opt["xs"][:n] || 0) * (opt["xs"][:minus] ? -1 : 1)
			else
				if gui.last_x == 0
					gui.padding
				else
					gui.last_x
				end
			end

			y = case
			when opt["y"]?
				opt["y"][:n] || 0
			when opt["yp"]?
				gui.last_y + (opt["yp"][:n] || 0) * (opt["yp"][:minus] ? -1 : 1)
			when opt["ym"]?
				gui.padding + (opt["ym"][:n] || 0) * (opt["ym"][:minus] ? -1 : 1)
			when opt["ys"]?
				gui.last_section_y + (opt["ys"][:n] || 0) * (opt["ys"][:minus] ? -1 : 1)
			else
				if gui.last_y == 0
					gui.padding
				else
					gui.last_y + 12 + gui.padding # TODO:
				end
			end
			
			if opt["section"]?
				gui.last_section_x = x
				gui.last_section_y = y
			end

			w = opt["w"]?.try &.[:n] || -1
			h = opt["h"]?.try &.[:n] || -1
			
			widget.set_size_request w, h
			gui.fixed.put widget, x, y

			gui.last_x = x
			gui.last_y = y
			gui.last_widget = widget
		end
	end
end