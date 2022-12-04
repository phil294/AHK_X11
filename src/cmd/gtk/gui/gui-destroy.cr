class Cmd::Gtk::Gui::GuiDestroy < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.display.gui.gui_destroy(args[0])
	end
end