require "../base"

# TODO: INCOMPAT: incomplete
class Cmd::Gtk::Msgbox < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(thread)
		txt = @args[0]? ? thread.runner.str(@args[0]) : nil
		thread.runner.gui.msgbox(txt)
	end
end