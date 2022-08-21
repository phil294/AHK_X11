# TODO: INCOMPAT: incomplete
class Cmd::Gtk::Msgbox < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		text = "Press OK to continue."
		if args[0]?
			options = args[0].to_i?(strict: true) # TODO: where is strict necessary?
			if options
				title = args[1]? ? args[1].empty? ? nil : args[1] : nil
				text = args[2] if args[2]?
				if args[3]?
					timeout = args[3].to_f?(strict: true)
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