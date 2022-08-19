# require "malloc_pthread_shim"
require "gobject/gtk"
require "../logo"

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

		# For running Gtk code on the Gtk worker thread (`idle_add` tells GTK to run
		# the `block` in its free time),
		# so perfect for Gui modifications, new window requests etc.
		def act(&block)
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
				dialog = Gtk::MessageDialog.new text: txt || "Press OK to continue.", title: title, message_type: :info, buttons: :ok, urgency_hint: true, icon: @icon_pixbuf
				dialog.on_response do |_, response_id|
					response = Gtk::ResponseType.new(response_id)
					channel.send(nil)
					dialog.destroy
				end
				dialog.show
			end
			channel.receive
		end

		@tray_menu : Gtk::Menu? = nil
		@tray : Gtk::StatusIcon? = nil
		property icon_pixbuf : GdkPixbuf::Pixbuf? = nil
		getter default_icon_pixbuf : GdkPixbuf::Pixbuf? = nil
		def bytes_to_pixbuf(bytes)
			stream = Gio::MemoryInputStream.new_from_bytes(GLib::Bytes.new(bytes))
			GdkPixbuf::Pixbuf.new_from_stream(stream, nil)
		end
		def initialize_menu(runner)
			act do
				@tray = tray = Gtk::StatusIcon.new
				@icon_pixbuf = @default_icon_pixbuf = bytes_to_pixbuf logo_blob
				tray.from_pixbuf = @icon_pixbuf

				@tray_menu = tray_menu = Gtk::Menu.new

				item_help = Gtk::MenuItem.new_with_label "Help"
				item_help.on_activate do
					begin
						Process.run "xdg-open", ["https://phil294.github.io/AHK_X11/"]
					rescue e
						STDERR.puts e # TODO:
					end
				end
				tray_menu.append item_help
				tray_menu.append Gtk::SeparatorMenuItem.new
				item_edit = Gtk::MenuItem.new_with_label "Edit this script"
				item_edit.on_activate do
					if runner.script_file
						begin
							Process.run "gtk-launch \"$(xdg-mime query default text/plain)\" '#{runner.script_file.not_nil!.to_s}'", shell: true
						rescue e
							STDERR.puts e # TODO:
						end
					end
				end
				tray_menu.append item_edit
				tray_menu.append Gtk::SeparatorMenuItem.new
				item_exit = Gtk::MenuItem.new_with_label "Exit"
				item_exit.on_activate { runner.exit_app 0 }
				tray_menu.append item_exit
				tray_menu.append Gtk::SeparatorMenuItem.new

				tray.on_popup_menu do |icon, button, time|
					tray_menu.show_all
					tray_menu.popup(nil, nil, nil, nil, button, time)
				end
			end
		end
		def tray
			with self yield @tray.not_nil!, @tray_menu.not_nil!
		end

		class ControlInfo
			getter control : Gtk::Widget
			getter alt_submit = false
			def initialize(@control, @alt_submit)
			end
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
			getter var_control_info = {} of String => ControlInfo
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
					window = Gtk::Window.new title: @@default_title, window_position: Gtk::WindowPosition::CENTER, icon: @icon_pixbuf
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