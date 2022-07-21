require "../../base"

class Cmd::Gtk::Gui::Gui < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 100 end
	def run(thread, args)
		thread.runner.gui.some_gui
	end
end