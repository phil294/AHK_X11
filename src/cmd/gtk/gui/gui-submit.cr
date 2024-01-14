# Submit [, NoHide]
class Cmd::Gtk::Gui::GuiSubmit < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread, args)
		gui_id = args[0]
		no_hide = args[1]? && args[1].downcase == "nohide"

		thread.runner.display.gtk.gui(thread, gui_id) do |gui|
			gui.var_control_info.each do |var_name, info|
				ctrl = info.control
				value = case
				when ctrl.is_a?(::Gtk::Entry) then ctrl.text
				when ctrl.is_a?(::Gtk::ScrolledWindow) then
					ctrl.children[0].unsafe_as(::Gtk::TextView).buffer.text
				when ctrl.is_a?(::Gtk::CheckButton) then
					ctrl.active ? "1" : "0"
				when ctrl.is_a?(::Gtk::ComboBoxText) then
					if info.alt_submit
						(ctrl.active + 1).to_s
					else
						begin
							ctrl.active_text
						rescue
							""
						end
					end
				end
				next if ! value
				thread.runner.set_user_var(var_name, value)
			end
			gui.window.hide if ! no_hide
		end
	end
end