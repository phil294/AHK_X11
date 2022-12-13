class Cmd::Gtk::FileSelectFolder < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 4 end
	def run(thread, args)
		out_var = args[0]
		options = (args[2]? || "").downcase
		root_dir = args[1]?
		prompt = args[3]? || "Select Folder - " + thread.runner.get_global_var("a_scriptname").not_nil!
		channel = Channel(::String).new
		thread.runner.display.gui.act do
			dialog = ::Gtk::FileChooserDialog.new title: prompt, action: ::Gtk::FileChooserAction::SELECT_FOLDER
			dialog.add_button "Cancel", ::Gtk::ResponseType::CANCEL.value
			dialog.add_button "Open", ::Gtk::ResponseType::OK.value
			dialog.current_folder = root_dir if root_dir
			dialog.on_response do |_, response_id|
				response = ::Gtk::ResponseType.new(response_id)
				filename = response == ::Gtk::ResponseType::OK ? (dialog.filename || "") : ""
				channel.send(filename)
				dialog.destroy
			end
			dialog.show
		end
		filename = channel.receive
		thread.runner.set_user_var(out_var, filename)
	end
end