# GuiControl, Sub-command, ControlID [, Param3]
class Cmd::Gtk::Gui::GuiControl < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def self.sets_error_level; true end
	def run(thread, args)
		gui_id, sub_cmd = Build::Parser.gui_sub_instruction_to_id_and_cmd(args[0])
		control_var_name = args[1]
		value = args[2]? || ""
		thread.runner.display.gtk.gui(thread, gui_id) do |gui|
			control_info = gui.var_control_info[control_var_name]
			next "1" if ! control_info
			ctrl = control_info.control
			case sub_cmd
			when ""
				case ctrl
				when ::Gtk::CheckButton
					if value == "1"
						ctrl.active = true
					elsif value == "0"
						ctrl.active = false
					else
						ctrl.label = value
					end
				when ::Gtk::ScrolledWindow
					ctrl.children[0].unsafe_as(::Gtk::TextView).buffer.text = value
				when ::Gtk::Button, ::Gtk::Label
					ctrl.label = value
				when ::Gtk::Entry
					ctrl.text = value
				when ::Gtk::EventBox
					img = ctrl.children[0].unsafe_as(::Gtk::Image)
					pixbuf_before = img.pixbuf
					LibGtk.gtk_widget_get_size_request(img.to_unsafe, out w, out h)
					img.from_file = value
					if (pixbuf_after = img.pixbuf) && (w > -1 || h > -1)
						if w == -1
							w = (h * pixbuf_after.width / pixbuf_after.height).to_i
						elsif h  == -1
							h = (w * pixbuf_after.height / pixbuf_after.width).to_i
						end
						pixbuf_after_scaled = pixbuf_after.scale_simple w, h, GdkPixbuf::InterpType::Bilinear
						img.pixbuf = pixbuf_after_scaled if pixbuf_after_scaled
					end
				else
					raise Run::RuntimeException.new "GuiControl not yet supported for element of type #{ctrl.class}, sorry."
				end
			end
		end
		"0"
	end
end