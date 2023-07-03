# Add, ControlType [, Options, Text]
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
				runner.add_thread g_label, 0
			end
		}

		w = (opt["w"]?.try &.[:n] || -1).to_i
		h = (opt["h"]?.try &.[:n] || -1).to_i

		thread.runner.display.gtk.gui(thread, gui_id) do |gui|
			widget : ::Gtk::Widget? = nil
			case type.downcase
			when "edit"
				if opt["r"]?.try &.[:n].try &.> 1
					widget = ::Gtk::ScrolledWindow.new vexpand: true, hexpand: false, shadow_type: ::Gtk::ShadowType::In
					buffer = ::Gtk::TextBuffer.new
					text_view = ::Gtk::TextView.new_with_buffer buffer
					text_view.accepts_tab = false
					text_view.wrap_mode = ::Gtk::WrapMode::WordChar
					text_view.margin = 5
					widget.add text_view
					text_view.buffer.set_text text, -1
					text_view.buffer.changed_signal.connect run_g_label
				else
					widget = ::Gtk::Entry.new
					widget.text = text
					widget.changed_signal.connect run_g_label
				end
			when "button" # TODO: "default" stuff from docs
				widget = ::Gtk::Button.new label: text
				widget.clicked_signal.connect run_g_label
				button_click_label = "button" + text.gsub(/[ &\n\r]/, "").downcase
				widget.clicked_signal.connect do
					runner.add_thread button_click_label, 0
				end
			when "checkbox"
				widget = ::Gtk::CheckButton.new label: text
				widget.active = true if opt["checked"]?
				widget.toggled_signal.connect run_g_label
			when "dropdownlist", "ddl"
				widget = ::Gtk::ComboBoxText.new
				text.split('|').each_with_index do |option, i|
					if option.empty? && i > 0
						widget.active = i - 1
					else
						widget.append_text option
					end
				end
				widget.active = ((opt["choose"][:n] || 1_i64) - 1).to_i if opt["choose"]?
				widget.changed_signal.connect run_g_label
			when "picture", "pic"
				widget = ::Gtk::Image.new_from_file text
				widget.has_window = true
				widget.events = ::Gdk::EventMask::ButtonPressMask.to_i
				widget.button_press_event_signal.connect run_g_label.unsafe_as(Proc(Gdk::EventButton, Bool))
				if (pixbuf = widget.pixbuf) && (w > -1 || h > -1)
					if w == -1
						w = (h * pixbuf.width / pixbuf.height).to_i
					elsif h  == -1
						h = (w * pixbuf.height / pixbuf.width).to_i
					end
					pixbuf_scaled = pixbuf.scale_simple w, h, GdkPixbuf::InterpType::Bilinear
					widget.pixbuf = pixbuf_scaled if pixbuf_scaled
				end
			else
				widget = ::Gtk::Label.new text
				widget.has_window = true
				widget.events = ::Gdk::EventMask::ButtonPressMask.to_i
				widget.button_press_event_signal.connect run_g_label.unsafe_as(Proc(Gdk::EventButton, Bool))
			end

			widget.override_background_color(::Gtk::StateFlags::Normal, gui.control_color) if gui.control_color

			if opt["v"]?
				alt_submit = !! opt["altsubmit"]?
				gui.var_control_info[opt["v"][:v]] = Run::Gtk::ControlInfo.new widget, alt_submit
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
				gui.last_x + (opt["xp"][:n] || 0).to_i * (opt["xp"][:minus] ? -1 : 1)
			when opt["xm"]?
				gui.padding + (opt["xm"][:n] || 0).to_i * (opt["xm"][:minus] ? -1 : 1)
			when opt["xs"]?
				gui.last_section_x + (opt["xs"][:n] || 0).to_i * (opt["xs"][:minus] ? -1 : 1)
			when opt["x"]?
				x_ = (opt["x"][:n] || 0).to_i
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
				gui.last_y + (opt["yp"][:n] || 0).to_i * (opt["yp"][:minus] ? -1 : 1)
			when opt["ym"]?
				gui.padding + (opt["ym"][:n] || 0).to_i * (opt["ym"][:minus] ? -1 : 1)
			when opt["ys"]?
				gui.last_section_y + (opt["ys"][:n] || 0).to_i * (opt["ys"][:minus] ? -1 : 1)
			when opt["y"]?
				(opt["y"][:n] || 0).to_i
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

			if w > -1 || h > -1
				widget.style_context.add_class("no-padding")
			end

			widget.set_size_request w, h
			gui.fixed.put widget, x, y

			gui.last_x = x
			gui.last_y = y
			gui.last_widget = widget
		end
	end
end