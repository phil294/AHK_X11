require "../base"

class Cmd::Gtk::Edit < Cmd::Base
	def run(thread, args)
		thread.runner.gui.open_edit(thread.runner)
	end
end