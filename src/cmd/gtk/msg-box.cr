# TODO: INCOMPAT: incomplete
class Cmd::Gtk::Msgbox < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.gui.msgbox(args[0]?)
	end
end