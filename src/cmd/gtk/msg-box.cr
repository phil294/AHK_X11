# TODO: INCOMPAT: incomplete
class Cmd::Gtk::Msgbox < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		text = "Press OK to continue."
		if args[0]?
			maybe_options = args[0].to_i? # TODO: where is strict necessary?
			if maybe_options && args[1]?
				options = maybe_options
				title = args[1].empty? ? nil : args[1]
				text = args[2] if args[2]?
				if args[3]?
					timeout = args[3].to_f?
					if ! timeout
						text += ", #{args[3]}" # TODO: uncool and potentially wrong (happens somewhere in parser too)
					end
				end
			else
				text = args[0..].join(", ") # TODO: .
			end
		end
		options ||= 0
		response = thread.runner.gui.msgbox(text, options: options, title: title, timeout: timeout)
		thread.settings.msgbox_response = response
	end
end