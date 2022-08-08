require "../../base"

class Cmd::Gtk::Gui::GuiSubmit < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread, args)
		gui_id = args[0]
		no_hide = args[1]? && args[1].downcase == "nohide"
		
		thread.runner.gui.gui(gui_id) do |gui|
			gui.var_control_info.each do |var_name, info|
				ctrl = info.control
				value = case
				when ctrl.is_a?(::Gtk::Entry) then ctrl.text
				when ctrl.is_a?(::Gtk::ScrolledWindow) then
					text_buffer = ctrl.children.next.unsafe_as(::Gtk::TextView).buffer
					iter_start = ::Gtk::TextIter.new
					iter_end = ::Gtk::TextIter.new
					text_buffer.start_iter iter_start
					text_buffer.end_iter iter_end
					text_buffer.text(iter_start, iter_end, true)
				when ctrl.is_a?(::Gtk::CheckButton) then
					ctrl.active ? "1" : "0"
				end
				next if ! value
				thread.runner.set_user_var(var_name, value)
			end
			gui.window.hide if ! no_hide
		end
	end
end