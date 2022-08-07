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
			channel = Channel(Exception?).new
			GLib.idle_add do
				begin
					block.call
				rescue e
					channel.send(e)
					next false
				end
				channel.send(nil)
				false
			end
			error = channel.receive
			raise RuntimeException.new error.message, error.cause if error
			nil
		end

		@@default_title = ARGV[0]? || PROGRAM_NAME

		# Only run this after `run` has started, as it depends on a running gtk main.
		# If you don't see the popup, it may be because of focus stealing prevention from the
		# window manager, please see the README.
		def msgbox(txt, *, title = @@default_title)
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

		private class GuiInfo
			getter window : Gtk::Window
			getter fixed : Gtk::Fixed
			property last_widget : Gtk::Widget? = nil
			property last_x = 0
			property last_y = 0
			property padding = 0
			property last_section_x = 0
			property last_section_y = 0
			def initialize(@window, @fixed)
			end
		end
		@guis = {} of String => GuiInfo
		# Yields (and if not yet exists, creates) the gui info referring to *gui_id*,
		# including the `window`, and passes the block on to the GTK idle thread so
		# you can run GTK code with it.
		def gui(gui_id, &block : GuiInfo -> _)
			gui_info = @guis[gui_id]?
			if ! gui_info
				act do
					window = Gtk::Window.new title: @@default_title, window_position: Gtk::WindowPosition::CENTER
					# , border_width: 20
					fixed = Gtk::Fixed.new
					window.add fixed
					gui_info = GuiInfo.new(window, fixed)
				end
				@guis[gui_id] = gui_info.not_nil!
			end
			act do
				block.call(gui_info.not_nil!)
			end
		end
	end
end