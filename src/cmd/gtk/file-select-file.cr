class Cmd::Gtk::FileSelectFile < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 5 end
	def run(thread, args)
		out_var = args[0]
		options = (args[1]? || "").downcase
		root_dir = args[2]?
		prompt = args[3]? || "Select File - " + thread.runner.get_global_var("a_scriptname").not_nil!
		channel = Channel(::String).new
		thread.runner.gui.act do
			if options.includes?('s')
				action = ::Gtk::FileChooserAction::SAVE
				do_overwrite_confirmation = true
			else
				action = ::Gtk::FileChooserAction::OPEN
			end
			dialog = ::Gtk::FileChooserDialog.new title: prompt, action: action, do_overwrite_confirmation: do_overwrite_confirmation
			dialog.add_button "Cancel", ::Gtk::ResponseType::CANCEL.value
			dialog.add_button (action == ::Gtk::FileChooserAction::SAVE ? "Save" : "Open"), ::Gtk::ResponseType::OK.value
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