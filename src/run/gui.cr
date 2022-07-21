# require "malloc_pthread_shim"
require "gobject/gtk"

module Run
	class Gui
		def run
			_argc = 0
			LibGtk.init pointerof(_argc), Pointer(UInt8**).new(0)
			LibGtk.main
		end

		private def act(&block)
			GLib.idle_add do
				block.call
				false
			end
		end

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