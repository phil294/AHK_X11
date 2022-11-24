require "x11"
require "xtst"
require "./display-adapter"

at_exit { GC.collect }

module X11::C
	# Infer a long list of key names from lib/x11/src/x11/c/keysymdef.cr, stripped from XK_ and underscores.
	# Seems to be necessary because XStringToKeysym is always case sensitive (?)
	def self.ahk_key_name_to_keysym_generic
		{{
			@type.constants # TODO: possible to declare this outside of the module?
				.select { |c| c.stringify.starts_with?("XK_") } # && c.underlying-var-type.is_a?(Int32) < TODO: how to, so the bools are skipped? (and `|| ! sym.is_a?(Int32)` can be removed)
				.reduce({} of String => Int32) do |acc, const_name|
					key_name = const_name.stringify[3..].downcase
					acc[key_name.gsub(/_/, "")] = const_name
					acc[key_name] = const_name
					acc
				end
		}}
	end
	# these are ahk-specific
	def self.ahk_key_name_to_keysym_custom
		{
			"enter" => XK_Return,
			"esc" => XK_Escape,
			"bs" => XK_BackSpace,
			"del" => XK_Delete,
			"ins" => XK_Insert,
			"pgup" => XK_Page_Up,
			"pgdown" => XK_Page_Down,
			"printscreen" => XK_Print,

			# Could not find the constants for these
			"lbutton" => 1,
			"rbutton" => 3,
			"mbutton" => 2,
			"wheeldown" => 5,
			"wheelup" => 4,
			"wheelleft" => 6, # [v1.0.48+]
			"wheelright" => 7, # [v1.0.48+]
			"xbutton1" => 8,
			"xbutton2" => 9,

			# TODO: Joystick buttons

			# The following special keys were determined either using `xev` or with https://github.com/qtile/qtile/blob/master/libqtile/backend/x11/xkeysyms.py (x11 must have them somewhere too??). TODO: These are mostly untested out of a loack of fitting keyboard.
			"volume_mute" => 0x1008ff12, # XF86AudioMute
			"volume_down" => 0x1008ff11, # XF86AudioLowerVolume
			"volume_up" => 0x1008ff13, # XF86AudioRaiseVolume
			"browser_back" => 0x1008ff26, # XF86Back
			"browser_forward" => 0x1008ff27, # XF86Forward
			"browser_refresh" => 0x1008ff73, # XF86Reload
			"browser_search" => 0x1008ff1b, # XF86Search
			"browser_homepage" => 0x1008ff18, # XF86HomePage
			"browser_stop" => 0x1008FF28, # XF86Stop
			"browser_favorites" => 0x1008FF30, # XF86Favorites
			"media_next" => 0x1008FF17, # XF86AudioNext
			"media_prev" => 0x1008FF16, # XF86AudioPrev
			"media_stop" => 0x1008FF15, # XF86AudioStop
			"media_play_pause" => 0x1008FF14, # XF86AudioPlay ?or? XF86AudioPause 0x1008FF31
			"launch_mail" => 0x1008FF19, # XF86Mail
			"launch_media" => 0x1008FF32, # XF86AudioMedia
			"launch_app1" => 0x1008FF5D, # XF86Explorer
			"launch_app2" => 0x1008FF1D, # XF86Calculator
			"ctrlbreak" => XK_Break,
			"sleep" => 0x1008FF2F, # XF86Sleep
			"numpaddiv" => XK_KP_Divide,
			"numpadmult" => XK_KP_Multiply,
			"numpadadd" => XK_KP_Add,
			"numpadsub" => XK_KP_Subtract,
			"numpadenter" => XK_KP_Enter,
			"numpaddel" => XK_KP_Delete,
			"numpadins" => XK_KP_Insert,
			"numpadclear" => XK_KP_Begin,
			"numpadup" => XK_KP_Up,
			"numpaddown" => XK_KP_Down,
			"numpadleft" => XK_KP_Left,
			"numpadright" => XK_KP_Right,
			"numpadhome" => XK_KP_Home,
			"numpadend" => XK_KP_End,
			"numpadpgup" => XK_KP_Page_Up,
			"numpadpgdn" => XK_KP_Page_Down,
			"numpad0" => XK_KP_0,
			"numpad1" => XK_KP_1,
			"numpad2" => XK_KP_2,
			"numpad3" => XK_KP_3,
			"numpad4" => XK_KP_4,
			"numpad5" => XK_KP_5,
			"numpad6" => XK_KP_6,
			"numpad7" => XK_KP_7,
			"numpad8" => XK_KP_8,
			"numpad9" => XK_KP_9,
			"numpaddot" => XK_KP_Decimal,
			"appskey" => XK_Menu,
			"lwin" => XK_Super_L,
			"rwin" => XK_Super_R,
			"control" => XK_Control_L,
			"ctrl" => XK_Control_L,
			"lcontrol" => XK_Control_L,
			"lctrl" => XK_Control_L,
			"rcontrol" => XK_Control_R,
			"rctrl" => XK_Control_R,
			"shift" => XK_Shift_L,
			"lshift" => XK_Shift_L,
			"rshift" => XK_Shift_R,
			"alt" => XK_Alt_L,
			"lalt" => XK_Alt_L,
			"ralt" => XK_Alt_R,
			# TODO: capslock?

			# Printable non-letters, symbols ;%@ etc.: Often their unicode ord is equal
			# to the keysym so the fallback should work. Below are only known exceptions
			"\n" => XK_Return,
			"\t" => XK_Tab,

			# TODO:
			# RAlt -- Note: If your keyboard layout has AltGr instead of RAlt, you can probably use it as a hotkey prefix via <^>! as described here. In addition, "LControl & RAlt::" would make AltGr itself into a hotkey.
		}
	end
end

module Run
	# Responsible for registering hotkeys to the X11 server,
	# listening to all events and calling threads on hotkey trigger
	# and calling given event listeners.
	class X11 < DisplayAdapter
		# include ::X11 # removed because of https://github.com/TamasSzekeres/x11-cr/issues/15 and who knows what else

		@root_win = 0_u64
		@record_context : ::Xtst::LibXtst::RecordContext?
		@record : ::Xtst::RecordExtension?
		getter display : ::X11::Display
		getter root_win : ::X11::Window

		def initialize
			set_error_handler

			@display = ::X11::Display.new
			@root_win = @display.root_window @display.default_screen_number

			begin
				@record = record = ::Xtst::RecordExtension.new
				record_range = record.create_range
				record_range.device_events.first = ::X11::KeyPress
				record_range.device_events.last = ::X11::ButtonRelease
				@record_context = record.create_context(record_range)
			rescue e
				# TODO: msgbox?
				STDERR.puts e
				STDERR.puts "The script will continue but some features (esp. Hotstrings) may not work. Please also consider opening an issue at github.com/phil294/ahk_x11 and tell us about your system details."
			end
		end

		def finalize
			@display.close
			@record.not_nil!.close if @record
		end

		def keysym_to_keycode(sym : UInt64)
			@display.keysym_to_keycode(sym)
		end

		def self.ahk_key_name_to_keysym(key_name)
			return nil if key_name.empty?
			down = key_name.downcase
			lookup = ::X11::C.ahk_key_name_to_keysym_generic[down]? ||
			::X11::C.ahk_key_name_to_keysym_custom[down]?
			return lookup if lookup
			char = key_name[0]
			return nil if char >= 'A' && char < 'Z' || char >= 'a' && char <= 'z'
			# This fallback may fail but it's very likely this is the correct match now.
			# This is the normal path for special chars like . @ $ etc.
			char.ord
		end

		# Makes sure the program doesn't exit when a Hotkey is not free for grabbing
		private def set_error_handler
			# Cannot use *any* outside variables here because any closure somehow makes set_error_handler never return, even with uninitialized (?why?), so we cannot set variables, show popup, nothing
			::X11.set_error_handler ->(display : ::X11::C::X::PDisplay, error_event : ::X11::C::X::PErrorEvent) do
				buffer = Array(UInt8).new 1024
				::X11::C::X.get_error_text display, error_event.value.error_code, buffer.to_unsafe, 1024
				error_message = String.new buffer.to_unsafe
				if error_event.value.error_code == 10
					STDERR.puts "Display server failed with 'BadAccess'. This most likely means that you are trying to register a Hotkey that is already grabbed by another application. The script will continue but your Hotkey will not work."
				else
					STDERR.puts "Display server unexpectedly failed with the following error message:\n\n#{error_message}\n\nThe script will exit."
					::exit 5
				end
				1
			end
		end

		@key_handler : Proc(::X11::KeyEvent, UInt64, Char?, Nil)?
		def run(*, key_handler)
			@key_handler = key_handler
			if record = @record
				record.enable_context_async(@record_context.not_nil!) do |record_data|
					handle_record_event(record_data)
				end
				record_fd = IO::FileDescriptor.new record.data_display.connection_number
				loop do
					loop do
						break if @display.pending == 0
						# Although events from next_event aren't used in this case, this queue apparently
						# still must always be empty. If not, the hotkeys aren't even grabbed.
						@display.next_event
					end
					record_fd.not_nil!.wait_readable
					record.process_replies
				end
			else
				# Misses non-grabbed keys and mouse events. It could also be done this way
				# (see old commits), but only unreliably and not worth the effort.
				loop do
					event = @display.next_event # Blocking!
					if event.is_a? ::X11::KeyEvent
						handle_key_event(event)
					end
				end
			end
		end

		private def handle_record_event(record_data)
			return if record_data.category != Xtst::LibXtst::RecordInterceptDataCategory::FromServer.value
			type, keycode, repeat = record_data.data
			state = record_data.data[28]
			return if repeat == 1
			_key_event = ::X11::KeyEvent.new
			_key_event.display = @display
			_key_event.type = type
			_key_event.keycode = keycode
			_key_event.state = state
			if keycode < 10 # mouse button
				# pretend that keysym = keycode
				@key_handler.not_nil!.call(_key_event, keycode.to_u64, nil)
			else
				handle_key_event(_key_event)
			end
		end

		private def handle_key_event(key_event)
			lookup = key_event.lookup_string
			char = lookup[:string][0]?
			keysym = lookup[:keysym]
			@key_handler.not_nil!.call(key_event, keysym, char)
		end

		def grab_hotkey(hotkey)
			hotkey.modifier_variants.each do |mod|
				if hotkey.keysym < 10
					@display.grab_button(hotkey.keysym.to_u32, mod, grab_window: @root_win, owner_events: true, event_mask: ::X11::ButtonPressMask.to_u32, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync, confine_to: ::X11::None.to_u64, cursor: ::X11::None.to_u64)
				else
					@display.grab_key(hotkey.keycode, mod, grab_window: @root_win, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync)
				end
			end
		end
		def ungrab_hotkey(hotkey)
			hotkey.modifier_variants.each do |mod|
				@display.ungrab_key(hotkey.keycode, mod, grab_window: @root_win)
			end
		end
	end
end