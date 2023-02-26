# GuiControl, Sub-command, ControlID [, Param3]
class Cmd::Gtk::Gui::GuiControl < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def self.sets_error_level; true end
	def run(thread, args)
		match = args[0].match(/(?:(\S+)\s*:\s*)?(.*)/).not_nil!
		gui_id = match[1]? || "1"
		sub_cmd = match[2]
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
				end
			end
		end
		"0"
	end
end