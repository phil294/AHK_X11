class Cmd::Gtk::Edit < Cmd::Base
	def run(thread, args)
		thread.runner.display.gtk.open_edit(thread.runner)
	end
end