require "gtk3"
require "../../logo"

module Run
	# Please note that all GUI logic needs to happen on the same worker thread where `run` was called
	# because anything else can result in undefined behavior (in fact, it just doesn't work).
	# That's why all GUI commands need to somehow pass through `Gui.act`.
	class Gtk
		@default_title : String
		def initialize(@default_title)
		end

		def run
			LibGtk.gtk_init(Pointer(Int32).null, Pointer(Pointer(Pointer(LibC::Char))).null)
			::Gtk.main
		end

		@act_mutex = Mutex.new
		# For running Gtk code on the Gtk worker thread (`idle_add` tells GTK to run
		# the `block` in its free time),
		# so perfect for Gui modifications, new window requests etc.
		def act(&block : -> T) forall T
			@act_mutex.lock
			channel = Channel(T | Exception).new
			GC.collect
			GC.disable
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
			exception : Exception? = nil
			if result.is_a?(Exception)
				# This must happen here before the GC collect because even stacktraces themselves can disappear
				exception = RuntimeException.new result.message, result.cause
			end
			GC.enable
			GC.collect
			@act_mutex.unlock
			# TODO: sub stack trace is lost here, e.g. if thrown somewhere inside gui-show
			raise exception if exception
			result.as(T)
		end

		def clipboard(&block : ::Gtk::Clipboard -> _)
			act do
				clip = ::Gtk::Clipboard.get(Gdk::Atom.intern("CLIPBOARD", true))
				block.call(clip)
			end
		end

		# Can't use @[Flags] because some values are *not* strict 2^n
		enum MsgBoxOptions
			OK = 0
			OK_Cancel = 1
			Abort_Retry_Ignore = 2
			Yes_No_Cancel = 3 # for some reason which is not the same as 1+2. Similar below
			Yes_No = 4
			Retry_Cancel = 5 # .
			# Unused_8 = 8
			Icon_Stop = 16
			Icon_Question = 32
			Icon_Exclamation = 48 # .
			Icon_Info = 64
			# Unused_128
			Button_2_Default = 256
			Button_3_Default = 512
			# Unused_1024
			# Unused_2048
			Always_On_Top = 4096
			# TODO: ?
			Task_Modal = 8192
		end
		# ::Gtk::ButtonsType/ResponseType is way too patchy, it is much more concise to write custom ids.
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
			buttons = case
			when options & MsgBoxOptions::Retry_Cancel.value == MsgBoxOptions::Retry_Cancel.value
				[MsgBoxButton::Retry, MsgBoxButton::Cancel]
			when options & MsgBoxOptions::Yes_No.value == MsgBoxOptions::Yes_No.value
				[MsgBoxButton::Yes, MsgBoxButton::No]
			when options & MsgBoxOptions::Yes_No_Cancel.value == MsgBoxOptions::Yes_No_Cancel.value
				[MsgBoxButton::Yes, MsgBoxButton::No, MsgBoxButton::Cancel]
			when options & MsgBoxOptions::Abort_Retry_Ignore.value == MsgBoxOptions::Abort_Retry_Ignore.value
				[MsgBoxButton::Abort, MsgBoxButton::Retry, MsgBoxButton::Ignore]
			when options & MsgBoxOptions::OK_Cancel.value == MsgBoxOptions::OK_Cancel.value
				[MsgBoxButton::OK, MsgBoxButton::Cancel]
			else [MsgBoxButton::OK]
			end
			# Deletable=false removes the x button but pressing Escape still works and returns delete(cancel) event response.
			# Wasn't easily fixable when I researched this.
			deletable = buttons.includes?(MsgBoxButton::Cancel)
			# Note that setting message_type does not show an image on many distros, only on Ubuntu: https://discourse.gnome.org/t/gtk3-message-dialog-created-with-gtk-message-dialog-new-shows-no-icon-on-fedora/8607
			# Setting dialog.image does not work either. The only native fix appears to be to switch to ::Gtk::Dialog
			# and add text and image manually (refer to Ubuntu patch from link).
			# However, since ahk_x11 is now officially always packaged using AppImage, built on *Ubuntu* 20.04, the
			# images will correctly appear everywhere, always.
			message_type = case
			when options & MsgBoxOptions::Icon_Info.value == MsgBoxOptions::Icon_Info.value
				::Gtk::MessageType::Info
			when options & MsgBoxOptions::Icon_Exclamation.value == MsgBoxOptions::Icon_Exclamation.value
				::Gtk::MessageType::Warning
			when options & MsgBoxOptions::Icon_Question.value == MsgBoxOptions::Icon_Question.value
				::Gtk::MessageType::Question
			when options & MsgBoxOptions::Icon_Stop.value == MsgBoxOptions::Icon_Stop.value
				::Gtk::MessageType::Error
			else nil
			end
			always_on_top = options & MsgBoxOptions::Always_On_Top.value == MsgBoxOptions::Always_On_Top.value
			channel = Channel(MsgBoxButton).new
			gtk_dialog = act do
				dialog = ::Gtk::MessageDialog.new text: text, title: title || @default_title, urgency_hint: true, icon: @icon_pixbuf, buttons: ::Gtk::ButtonsType::None, message_type: message_type, deletable: deletable, skip_taskbar_hint: false
				dialog.keep_above = always_on_top
				buttons.each do |btn|
					dialog.add_button btn.to_s, btn.value
				end
				dialog.response_signal.connect do |response_id|
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

		def inputbox(title, prompt, hide, w, h, x, y, timeout, default)
			title ||= @default_title
			prompt ||= ""
			w ||= 375
			h ||= 189
			timeout ||= 3_000_000_000_f64
			channel = Channel(NamedTuple(status: MsgBoxButton, response: String)).new
			gtk_window = act do
				window = ::Gtk::Window.new title: title, window_position: ::Gtk::WindowPosition::Center, icon: @icon_pixbuf, resizable: true
				vbox = ::Gtk::Box.new orientation: ::Gtk::Orientation::Vertical
				window.add vbox
				lbl = ::Gtk::Label.new label: prompt, xalign: 0, yalign: 0, margin_left: 5, margin_top: 5
				vbox.pack_start lbl, true, true, 0
				entry = ::Gtk::Entry.new text: default, visibility: !hide, margin_left: 5, margin_right: 5
				entry.activate_signal.connect do
					channel.send({ status: MsgBoxButton::OK, response: entry.text })
				end
				vbox.pack_start entry, false, false, 5
				hbox = ::Gtk::Box.new
				vbox.pack_start hbox, false, false, 5
				ok_btn = ::Gtk::Button.new label: "OK", width_request: 70
				ok_btn.clicked_signal.connect do
					channel.send({ status: MsgBoxButton::OK, response: entry.text })
				end
				hbox.pack_start ok_btn, true, false, 5
				cancel_btn = ::Gtk::Button.new label: "Cancel", width_request: 70
				cancel_btn.clicked_signal.connect do
					channel.send({ status: MsgBoxButton::Cancel, response: entry.text })
				end
				hbox.pack_start cancel_btn, true, false, 5
				window.key_press_event_signal.connect do |event|
					if event.keyval == 65307 # Esc
						channel.send({ status: MsgBoxButton::Cancel, response: entry.text })
					end
					false
				end
				window.destroy_signal.connect do
					if ! channel.closed?
						channel.send({ status: MsgBoxButton::Cancel, response: entry.text })
					end
				end
				window.set_default_size w, h
				window.move x, y if x && y
				window.show_all
				window
			end
			r = select
			when response = channel.receive
				response
			when timeout(timeout.seconds)
				{ status: MsgBoxButton::Timeout, response: "" }
			end
			channel.close
			act { gtk_window.destroy }
			r
		end

		@tray_menu : ::Gtk::Menu? = nil
		@tray : ::Gtk::StatusIcon? = nil
		property icon_pixbuf : GdkPixbuf::Pixbuf? = nil
		getter default_icon_pixbuf : GdkPixbuf::Pixbuf? = nil
		def bytes_to_pixbuf(bytes)
			stream = Gio::MemoryInputStream.new_from_bytes(GLib::Bytes.new(bytes.to_unsafe, bytes.size))
			GdkPixbuf::Pixbuf.new_from_stream(stream, nil)
		end
		private def init_menu(runner)
			act do
				@tray = tray = ::Gtk::StatusIcon.new
				@icon_pixbuf = @default_icon_pixbuf = bytes_to_pixbuf logo_blob
				tray.from_pixbuf = @icon_pixbuf

				@tray_menu = tray_menu = ::Gtk::Menu.new

				item_help = ::Gtk::MenuItem.new_with_label "Help"
				item_help.activate_signal.connect do
					begin
						Process.run "xdg-open", ["https://phil294.github.io/AHK_X11/"]
					rescue e
						STDERR.puts e # TODO:
					end
				end
				tray_menu.append item_help
				tray_menu.append ::Gtk::SeparatorMenuItem.new
				item_window_spy = ::Gtk::MenuItem.new_with_label "Window Spy"
				item_window_spy.activate_signal.connect { spawn { runner.launch_window_spy } }
				tray_menu.append item_window_spy
				item_reload = ::Gtk::MenuItem.new_with_label "Reload this script"
				item_reload.activate_signal.connect { runner.reload }
				tray_menu.append item_reload
				item_edit = ::Gtk::MenuItem.new_with_label "Edit this script"
				item_edit.activate_signal.connect { open_edit(runner) }
				tray_menu.append item_edit
				tray_menu.append ::Gtk::SeparatorMenuItem.new
				item_suspend = ::Gtk::MenuItem.new_with_label "Suspend Hotkeys"
				item_suspend.activate_signal.connect { spawn { runner.suspend } }
				tray_menu.append item_suspend
				item_pause = ::Gtk::MenuItem.new_with_label "Pause script"
				item_pause.activate_signal.connect { spawn { runner.pause_thread(self_is_thread: false) } }
				tray_menu.append item_pause
				item_exit = ::Gtk::MenuItem.new_with_label "Exit"
				item_exit.activate_signal.connect { runner.exit_app(0) }
				tray_menu.append item_exit
				tray_menu.append ::Gtk::SeparatorMenuItem.new

				tray.popup_menu_signal.connect do |button, time|
					tray_menu.show_all
					tray_menu.popup(nil, nil, nil, nil, button, time)
				end
			end
		end
		def init(runner)
			act do
				provider = ::Gtk::CssProvider.new
				::Gtk::StyleContext.add_provider_for_screen(Gdk::Display.default.not_nil!.default_screen, provider, ::Gtk::STYLE_PROVIDER_PRIORITY_APPLICATION.to_u32)
				provider.load_from_data("
					.no-padding { padding: 0; }
					.tooltip {
						background-color: rgb(255,255,226);
						color: rgb(87,87,87);
						padding: 2px; }
				".to_slice)
			end
			init_menu(runner)
		end
		def tray
			with self yield @tray.not_nil!, @tray_menu.not_nil!
		end
		# Instead of showing both Suspension and ThreadPause state simultaneously, only one is shown dynamically, with Pause taking precedence.
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
			return if ! @is_pause
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
					# TODO: rewrite all "shell: ?true" process runs to proper "prog", [args]
					Process.run "gtk-launch \"$(xdg-mime query default text/plain)\" '#{runner.script_file.not_nil!.to_s}'", shell: true
				rescue e
					STDERR.puts e # TODO:
				end
			end
		end

		class ControlInfo
			getter control : ::Gtk::Widget
			getter alt_submit = false
			def initialize(@control, @alt_submit)
			end
		end
		private class GuiInfo
			getter window : ::Gtk::Window
			getter fixed : ::Gtk::Fixed
			property last_widget : ::Gtk::Widget? = nil
			property last_x = 0
			property last_y = 0
			property padding = 0
			property last_section_x = 0
			property last_section_y = 0
			getter var_control_info = {} of String => ControlInfo
			property window_color : Gdk::RGBA? = nil
			property control_color : Gdk::RGBA? = nil
			def initialize(@window, @fixed)
			end
		end
		getter guis = {} of String => GuiInfo
		# This is necessary to be able to pass flags to the Gui Gtk Window *at creation time*, because
		# the respective flags can't be set again at a later time.
		# This is a rare occurrence and currently only necessary to set the type to Popup.
		# Note that this is different from properties that can only be set before a window is *shown*.
		# For that, the only thing that matters is the ordering of ahk commands.
		class GuiCreationInfo
			property type : ::Gtk::WindowType
			def initialize(*, @type)
			end
		end
		# :ditto:
		getter guis_creation_info = {} of String => GuiCreationInfo
		# Yields (and if not yet exists, creates) the gui info referring to *gui_id*,
		# including the `window`, and passes the block on to the GTK idle thread so
		# you can run GTK code with it.
		def gui(thread, gui_id, &block : GuiInfo -> _)
			if ! @guis[gui_id]?
				act do
					type = @guis_creation_info[gui_id]?.try &.type || ::Gtk::WindowType::Toplevel
					window = ::Gtk::Window.new title: @default_title, window_position: ::Gtk::WindowPosition::Center, icon: @icon_pixbuf, resizable: false, type: type
					# , border_width: 20
					fixed = ::Gtk::Fixed.new
					window.add fixed
					window_on_destroy = ->do
						close_label_id = gui_id == "1" ? "" : gui_id
						close_label = "#{close_label_id}GuiClose".downcase
						thread.runner.add_thread close_label, 0
					end
					window.destroy_signal.connect { window_on_destroy.call }
					# To support transparent background when invoked via WinSet:
					# Appears to be impossible to set dynamically, so needed at win build time:
					window.visual = window.screen.rgba_visual
					@guis[gui_id] = GuiInfo.new(window, fixed)
				end
			end
			act { block.call(@guis[gui_id]) }
		end
		def gui_destroy(gui_id)
			gui = @guis[gui_id]?
			return if ! gui
			act { gui.window.destroy }
			@guis.delete(gui_id)
		end
		@tooltips = {} of Int32 => ::Gtk::Window
		# Yields (and if not yet exists, creates) the tooltip referring to *tooltip_id*
		def tooltip(tooltip_id : Int32, &block : ::Gtk::Window -> _)
			if ! @tooltips[tooltip_id]?
				act do
					tooltip = ::Gtk::Window.new title: "AHK_X11 Tooltip #{tooltip_id.to_s}", window_position: ::Gtk::WindowPosition::Mouse, type_hint: ::Gdk::WindowTypeHint::Tooltip, accept_focus: false, can_focus: false, resizable: false, skip_taskbar_hint: true, type: ::Gtk::WindowType::Popup, decorated: false
					tooltip.keep_above = true
					txt = ::Gtk::Label.new "Label"
					# doesn't work, is grey?:
					# txt.override_background_color ::Gtk::StateFlags::Normal, ::Gdk::RGBA.new(1,1,1,1)
					# doesn't work, is blue??!: (new gi bindings only, used to work with prev ones)
					# txt.modify_bg ::Gtk::StateType::Normal, ::Gdk::Color.new(nil,65535,65535,57825)
					# Have to resort to css now:
					txt.style_context.add_class("tooltip")
					txt.override_font ::Pango::FontDescription.from_string("9")
					tooltip.add(txt)
					@tooltips[tooltip_id] = tooltip
				end
			end
			act do
				block.call(@tooltips[tooltip_id].not_nil!)
			end
		end
		def destroy_tooltip(tooltip_id)
			tooltip = @tooltips[tooltip_id]?
			return if ! tooltip
			act { tooltip.destroy }
			@tooltips.delete tooltip_id
		end
		def parse_rgba(v)
			if v.to_i?(16)
				v = "##{v}"
			end
			color = Gdk::RGBA.new(0,0,0,1)
			color.parse(v)
			color
		end
	end
end