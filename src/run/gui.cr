# require "malloc_pthread_shim"
require "gobject/gtk"

module Run
	# Please note that all GUI logic needs to happen on the same worker thread where `run` was called
	# because anything else can result in undefined behavior (in fact, it just doesn't work).
	# That's why all GUI commands need to somehow pass through `Gui.act`.
	class Gui
		def run
			_argc = 0
			# taken from "gobject/gtk/autorun". There's probably a better way.
			LibGtk.init pointerof(_argc), Pointer(UInt8**).new(0)
			LibGtk.main # blocking!
		end

		# `idle_add` tells GTK to run the `block` in its free time (on its own worker thread),
		# so perfect for Gui modifications, new window requests etc.
		private def act(&block)
			GLib.idle_add do
				block.call
				false
			end
		end

		# Only run this after `run` has started, as it depends on a running gtk main.
		# If you don't see the popup, it may be because of focus stealing prevention from the
		# window manager, please see the README.
		def msgbox(txt, *, title = ARGV[0]? || PROGRAM_NAME)
			channel = Channel(Nil).new
			act do
				dialog = Gtk::MessageDialog.new text: txt || "Press OK to continue.", title: title, message_type: :info, buttons: :ok, urgency_hint: true
				dialog.on_response do |_, response_id|
					response = Gtk::ResponseType.new(response_id)
					channel.send(nil)
					dialog.destroy
				end
				dialog.show
			end
			channel.receive
		end

		def some_gui
			act do
				window = Gtk::Window.new title: "Hello" # , border_width: 20
				lbl = Gtk::Label.new "Hello World!"
				window.add lbl
				window.show_all
			end
		end
	end
end