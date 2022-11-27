# require "malloc_pthread_shim"
require "gobject/gtk"
require "../../logo"

module Run
	# Please note that all GUI logic needs to happen on the same worker thread where `run` was called
	# because anything else can result in undefined behavior (in fact, it just doesn't work).
	# That's why all GUI commands need to somehow pass through `Gui.act`.
	class Gui
		@default_title : String
		def initialize(@default_title)
		end

		def run
			_argc = 0
			# taken from "gobject/gtk/autorun". There's probably a better way.
			LibGtk.init pointerof(_argc), Pointer(UInt8**).new(0)
			LibGtk.main # blocking!
		end

		# For running Gtk code on the Gtk worker thread (`idle_add` tells GTK to run
		# the `block` in its free time),
		# so perfect for Gui modifications, new window requests etc.
		def act(&block : -> T) forall T
			channel = Channel(T | Exception).new
			GLib.idle_add do
				begin
					result = block.call
				rescue e
					channel.send(e)
					next false
				end
				channel.send(result)
				false
			end
			result = channel.receive
			raise RuntimeException.new result.message, result.cause if result.is_a?(Exception)
			result
		end

		def clipboard(&block : Gtk::Clipboard -> _)
			act do
				clip = Gtk::Clipboard.get(Gdk::Atom.intern("CLIPBOARD", true))
				block.call(clip)
			end
		end

		@[Flags]
		private enum MsgBoxOptions
			OK_Cancel
			Abort_Retry_Ignore
			# Yes_No_Cancel = 3 # 3 for some reason which is not the same as 1+2 so it needs special handling. Similar below
			Yes_No
			# Retry_Cancel # 5
			Unused_8
			Icon_Stop = 16
			Icon_Question = 32
			# Icon_Exclamation = 48
			Icon_Info = 64
			Unused_128
			Button_2_Default = 256
			Button_3_Default = 512
			Unused_1024
			Unused_2048
			Always_On_Top = 4096
			# TODO: ?
			Task_Modal = 8192
		end
		# Gtk::ButtonsType/ResponseType is way too patchy, it is much more concise to write custom ids.
		enum MsgBoxButton
			OK = 1
			Cancel
			Abort
			Retry
			Ignore
			Yes
			No
			Timeout
		end

		# Only run this after `run` has started, as it depends on a running gtk main.
		# If you don't see the popup, it may be because of focus stealing prevention from the
		# window manager, please see the README.
		def msgbox(text, options = 0, title = nil, timeout = nil)
			msg_box_option_yes_no_cancel = MsgBoxOptions::OK_Cancel.value | MsgBoxOptions::Abort_Retry_Ignore.value
			msg_box_option_retry_cancel = MsgBoxOptions::OK_Cancel.value | MsgBoxOptions::Yes_No.value
			msg_box_option_icon_exclamation = MsgBoxOptions::Icon_Stop.value | MsgBoxOptions::Icon_Question.value
			buttons = case
			when options & msg_box_option_retry_cancel == msg_box_option_retry_cancel
				[MsgBoxButton::Retry, MsgBoxButton::Cancel]
			when options & MsgBoxOptions::Yes_No.value == MsgBoxOptions::Yes_No.value
				[MsgBoxButton::Yes, MsgBoxButton::No]
			when options & msg_box_option_yes_no_cancel == msg_box_option_yes_no_cancel
				[MsgBoxButton::Yes, MsgBoxButton::No, MsgBoxButton::Cancel]
			when options & MsgBoxOptions::Abort_Retry_Ignore.value == MsgBoxOptions::Abort_Retry_Ignore.value
				[MsgBoxButton::Abort, MsgBoxButton::Retry, MsgBoxButton::Ignore]
			when options & MsgBoxOptions::OK_Cancel.value == MsgBoxOptions::OK_Cancel.value
				[MsgBoxButton::OK, MsgBoxButton::Cancel]
			else [MsgBoxButton::OK]
			end
			# TODO: Deletable=false removes the x button but pressing Escape still works and returns delete(cancel) event response... wasn't easily fixable when I researched this.
			deletable = buttons.includes?(MsgBoxButton::Cancel)
			# TODO: Setting message_type does not show an image on many distros, only on Ubuntu: https://discourse.gnome.org/t/gtk3-message-dialog-created-with-gtk-message-dialog-new-shows-no-icon-on-fedora/8607
			# Setting dialog.image does not work either. The only solution appears to be to switch to Gtk::Dialog and add text and image manually (refer to Ubuntu patch from link).
			message_type = case
			when options & MsgBoxOptions::Icon_Info.value == MsgBoxOptions::Icon_Info.value
				Gtk::MessageType::INFO
			when options & msg_box_option_icon_exclamation == msg_box_option_icon_exclamation
				Gtk::MessageType::WARNING
			when options & MsgBoxOptions::Icon_Question.value == MsgBoxOptions::Icon_Question.value
				Gtk::MessageType::QUESTION
			when options & MsgBoxOptions::Icon_Stop.value == MsgBoxOptions::Icon_Stop.value
				Gtk::MessageType::ERROR
			else nil
			end
			always_on_top = options & MsgBoxOptions::Always_On_Top.value == MsgBoxOptions::Always_On_Top.value
			channel = Channel(MsgBoxButton).new
			gtk_dialog = act do
				dialog = Gtk::MessageDialog.new text: text, title: title || @default_title, urgency_hint: true, icon: @icon_pixbuf, buttons: Gtk::ButtonsType::NONE, message_type: message_type, deletable: deletable, skip_taskbar_hint: false
				dialog.keep_above = always_on_top
				buttons.each do |btn|
					dialog.add_button btn.to_s, btn.value
				end
				dialog.on_response do |_, response_id|
					if response_id <= 0 # i.e. DELETE_EVENT
						response_id = MsgBoxButton::Cancel.value
					end
					btn = MsgBoxButton.new(response_id)
					channel.send(btn)
					dialog.destroy
				end
				dialog.show
				dialog
			end
			! timeout ? channel.receive : select
			when response = channel.receive
				response
			when timeout(timeout ? timeout.seconds : Time::Span::MAX)
				act { gtk_dialog.destroy }
				MsgBoxButton::Timeout
			end
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
				item_reload = Gtk::MenuItem.new_with_label "Reload this script"
				item_reload.on_activate { runner.reload }
				tray_menu.append item_reload
				item_edit = Gtk::MenuItem.new_with_label "Edit this script"
				item_edit.on_activate { open_edit(runner) }
				tray_menu.append item_edit
				tray_menu.append Gtk::SeparatorMenuItem.new
				item_suspend = Gtk::MenuItem.new_with_label "Suspend Hotkeys"
				item_suspend.on_activate { spawn { runner.suspend } }
				tray_menu.append item_suspend
				item_pause = Gtk::MenuItem.new_with_label "Pause script"
				item_pause.on_activate { spawn { runner.pause_thread(self_is_thread: false) } }
				tray_menu.append item_pause
				item_exit = Gtk::MenuItem.new_with_label "Exit"
				item_exit.on_activate { runner.exit_app(0) }
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
		# Instead of showing both Suspension and ThreadPause state simultaneously, only one is showed dynamically, with Pause taking precedence.
		@is_suspend = false
		@is_pause = false
		def suspend
			@is_suspend = true
			return if @is_pause
			act { @tray.not_nil!.from_icon_name = "input-keyboard" }
		end
		def unsuspend
			@is_suspend = false
			return if @is_pause
			act { @tray.not_nil!.from_pixbuf = @icon_pixbuf }
		end
		def thread_pause
			return if @is_pause
			@is_pause = true
			act { @tray.not_nil!.from_icon_name = "content-loading-symbolic" }
		end
		def thread_unpause
			@is_pause = false
			if @is_suspend
				suspend
			else
				unsuspend
			end
		end

		def open_edit(runner)
			if runner.script_file
				begin
					Process.run "gtk-launch \"$(xdg-mime query default text/plain)\" '#{runner.script_file.not_nil!.to_s}'", shell: true
				rescue e
					STDERR.puts e # TODO:
				end
			end
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
		def gui(thread, gui_id, &block : GuiInfo -> _)
			gui_info = @guis[gui_id]?
			if ! gui_info
				act do
					window = Gtk::Window.new title: @default_title, window_position: Gtk::WindowPosition::CENTER, icon: @icon_pixbuf
					# , border_width: 20
					fixed = Gtk::Fixed.new
					window.add fixed
					window.connect "destroy" do
						close_label_id = gui_id == "1" ? "" : gui_id
						close_label = "#{close_label_id}GuiClose".downcase
						begin thread.runner.add_thread close_label, 0
						rescue e
							# TODO: ...
							STDERR.puts e
						end
					end
					gui_info = GuiInfo.new(window, fixed)
				end
				@guis[gui_id] = gui_info.not_nil!
			end
			act do
				block.call(gui_info.not_nil!)
			end
		end
		@tooltips = {} of Int32 => Gtk::Window
		# Yields (and if not yet exists, creates) the tooltip referring to *tooltip_id*
		def tooltip(tooltip_id : Int32, &block : Gtk::Window -> _)
			if ! @tooltips[tooltip_id]?
				act do
					tooltip = ::Gtk::Window.new title: "AHK_X11 Tooltip #{tooltip_id.to_s}", window_position: Gtk::WindowPosition::MOUSE, type_hint: ::Gdk::WindowTypeHint::TOOLTIP, accept_focus: false, can_focus: false, resizable: false, skip_taskbar_hint: true, type: ::Gtk::WindowType::POPUP, modal: true, decorated: false
					tooltip.keep_above = true
					txt = ::Gtk::Label.new "Label"
					txt.margin = 2
					# txt.override_background_color ::Gtk::StateFlags::NORMAL, ::Gdk::RGBA.new(1,1,1) # <- doesnt work, is grey? using modifybg instead which is even more deprecated
					# txt.override_color ::Gtk::StateFlags::NORMAL, ::Gdk::RGBA.new(0.341,0.341,0.341)
					txt.modify_bg ::Gtk::StateType::NORMAL, ::Gdk::Color.new(nil,65535,65535,65535)
					txt.modify_fg ::Gtk::StateType::NORMAL, ::Gdk::Color.new(nil,22359,22359,22359)
					txt.override_font ::Pango::FontDescription.from_string("8")
					tooltip.add(txt)
					@tooltips[tooltip_id] = tooltip
				end
			end
			act do
				block.call(@tooltips[tooltip_id].not_nil!)
			end
		end
	end
end