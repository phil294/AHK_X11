require "../../base"

class Cmd::Gtk::Gui::GuiAdd < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		gui_id = args[0]
		type = args[1]
		options = args[2]? || ""
		text = args[3]? || ""
		
		opt = thread.parse_word_options options
		runner = thread.runner
		g_label = opt["g"]?.try &.[:v].downcase
		run_g_label = ->{
			if g_label
				begin
					runner.add_thread g_label, 0
				rescue e
					STDERR.puts e # TODO: Add application-global logger which shows popop
					# (can't allow exceptions here because we're on the GUI thread)
				end
			end
		}
		
		thread.runner.gui.gui(gui_id) do |gui|
			widget : ::Gtk::Widget? = nil
			case type.downcase
			when "text"
				widget = ::Gtk::Label.new text
				widget.has_window = true
				widget.events = ::Gdk::EventMask::BUTTON_PRESS_MASK.to_i
				widget.connect "button-press-event", run_g_label
			when "edit"
				if opt["r"]?.try &.[:n].try &.> 1
					widget = ::Gtk::ScrolledWindow.new vexpand: true, hexpand: false, shadow_type: ::Gtk::ShadowType::IN
					buffer = ::Gtk::TextBuffer.new
					text_view = ::Gtk::TextView.new_with_buffer buffer
					text_view.accepts_tab = false
					text_view.wrap_mode = ::Gtk::WrapMode::WORD_CHAR
					text_view.margin = 5
					widget.add text_view
					text_view.buffer.set_text text, -1
					text_view.buffer.connect "changed", run_g_label
				else
					widget = ::Gtk::Entry.new
					widget.text = text
					widget.connect "changed", run_g_label
				end
			when "button"
				widget = ::Gtk::Button.new label: text
				widget.connect "clicked", run_g_label
				button_click_label = "button" + text.gsub(/ &\n\r/, "")
				widget.on_clicked do
					begin runner.add_thread button_click_label, 0
					rescue
					end
				end
			else
				raise Run::RuntimeException.new "Unknown Gui control '#{type}'"
			end

			if opt["v"]?
				gui.var_control_info[opt["v"][:v]] = Run::Gui::ControlInfo.new widget
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
			when opt["xp"]?
				gui.last_x + (opt["xp"][:n] || 0) * (opt["xp"][:minus] ? -1 : 1)
			when opt["xm"]?
				gui.padding + (opt["xm"][:n] || 0) * (opt["xm"][:minus] ? -1 : 1)
			when opt["xs"]?
				gui.last_section_x + (opt["xs"][:n] || 0) * (opt["xs"][:minus] ? -1 : 1)
			when opt["x"]?
				x_ = opt["x"][:n] || 0
				# x_ += gui.last_x + last_w if opt["x"][:plus]
				# x_ = gui.last_x + last_w - x_ if opt["x"][:minus]
				x_
			else
				if gui.last_x == 0
					gui.padding
				else
					gui.last_x
				end
			end

			y = case
			when opt["yp"]?
				gui.last_y + (opt["yp"][:n] || 0) * (opt["yp"][:minus] ? -1 : 1)
			when opt["ym"]?
				gui.padding + (opt["ym"][:n] || 0) * (opt["ym"][:minus] ? -1 : 1)
			when opt["ys"]?
				gui.last_section_y + (opt["ys"][:n] || 0) * (opt["ys"][:minus] ? -1 : 1)
			when opt["y"]?
				opt["y"][:n] || 0
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