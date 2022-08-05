require "x11"

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

			# TODO:
			# I tried so catch mouse events too by adding ButtonReleaseMask and then adding some
			# fake keysyms here for manual mapping (see WIP-add-mouse-hotkey-support branch).
			# This should mostly work but mouse events are almost never reported :(
			# LButton - the left mouse button 
			# RButton - the right mouse button 
			# MButton - the middle or wheel mouse button 
			# WheelDown - this is equivalent to rotating the mouse wheel down (toward you) 
			# WheelUp - the opposite of the above 
			# Supported only in Windows XP/2000+:
			# XButton1 - a button that appears only on certain mice 
			# XButton2 - a button that appears only on certain mice 
			# ...all joystick buttons

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
	# Responsible for registering hotkeys to the X11 server and calling threads on trigger.
	# Parts of the grab_key stuff is adopted from https://stackoverflow.com/q/4037230.
	# For a non-grabbing alternative that could also be used to implemented Hotstrings,
	# check the `x11-follow-focus` branch (broken) and https://stackoverflow.com/q/22749444
	class X11
		# include ::X11 # removed because of https://github.com/TamasSzekeres/x11-cr/issues/15 and who knows what else 

		@root_win = 0_u64
		@focussed_win = 0_u64
		def initialize
			@display = ::X11::Display.new
			@root_win = @display.root_window @display.default_screen_number
		end
		def finalize
			@display.close
		end

		def keysym_to_keycode(sym : UInt64)
			@display.keysym_to_keycode(sym)
		end

		def ahk_key_name_to_keysym(key_name)
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

		private def refresh_focus
			if @focussed_win != 0_u64 && @focussed_win != @root_win
				@display.select_input @focussed_win, 0 # unsubscribe
			end
			@focussed_win = @display.input_focus[:focus]
			if @focussed_win == ::X11::PointerRoot
				@focussed_win = @root_win
			end
			@display.select_input @focussed_win, ::X11::KeyReleaseMask | ::X11::FocusChangeMask # ButtonPressMask | ButtonReleaseMask | KeyPressMask | KeyReleaseMask | FocusChangeMask
		end

		def run(runner : Runner)
			refresh_focus
			loop do
				event = @display.next_event # blocking!
				# Currently, hotkeys are always based on key release event. Trigger on press introduced
				# repetition and trigger loop bugs that I couldn't resolve. (TODO:)
				case event
				when ::X11::KeyEvent
					next if @is_paused || ! event.release?
					handle_key_event event, runner
				when ::X11::FocusChangeEvent
					refresh_focus if event.out?
				end
			end
		end
		
		# multiple threads may request a pause. x11 will only resume after all have called
		# `resume_x11` again.
		# pausing x11 event handling can be very important in `Send` scenarios to prevent hotkeys
		# from triggering themselves (or others)
		@pause_counter = 0
		@is_paused = false
		@pause_mutex = Mutex.new
		def pause
			@pause_mutex.lock
			@pause_counter += 1
			@is_paused = true
			@pause_mutex.unlock
		end
		# before resume, x11 will discard all events collected since it got paused
		def resume
			@pause_mutex.lock
			@pause_counter -= 1
			if @pause_counter < 1
				@pause_counter = 0
				@is_paused = false
			end
			@pause_mutex.unlock
		end

		# apparently keycodes are display-dependent so they can't be determined at build time
		@hotkey_subscriptions = [] of NamedTuple(hotkey: Hotkey, keycode: UInt8)
		@hotstrings = [] of Hotstring

		def register_hotstring(hotstring)
			@hotstrings << hotstring
		end

		def register_hotkey(hotkey)
			keycode = keysym_to_keycode(hotkey.keysym)
			@hotkey_subscriptions << {
				hotkey: hotkey,
				keycode: keycode
			}
			if ! hotkey.no_grab
				hotkey.modifiers.each do |mod|
					@display.grab_key(keycode, mod, grab_window: @root_win, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync)
				end
			end
		end
		def unregister_hotkey(hotkey)
			i = @hotkey_subscriptions.index! { |sub| sub.[:hotkey] == hotkey }
			sub = @hotkey_subscriptions[i]
			sub[:hotkey].modifiers.each do |mod|
				@display.ungrab_key(sub[:keycode], mod, grab_window: @root_win)
			end
			@hotkey_subscriptions.delete i
		end

		@key_buff = HotstringAbbrevKeysyms.new('0')
		@key_buff_i = 0_u8

		@hotstring_end_chars : StaticArray(Char, 21)
		# Pressing return is a \r, not sure if \n even ever fires
		@hotstring_end_chars = StaticArray['-', '(', ')', '[', ']', '{', '}', ':', ';', '\'', '"', '/', '\\', ',', '.', '?', '!', '\n', ' ', '\t', '\r']
		@hotstring_candidate : Hotstring? = nil

		private def handle_key_event(event, runner)
			##### 1. Hotkeys
			sub = @hotkey_subscriptions.find do |sub|
				sub[:hotkey].active &&
				sub[:keycode] == event.keycode &&
				sub[:hotkey].modifiers.any? &.== event.state
			end
			sub[:hotkey].trigger if sub
			
			##### 2. Hotstrings
			lookup = event.lookup_string
			char = lookup[:string][0]?

			prev_hotstring_candidate = @hotstring_candidate
			@hotstring_candidate = nil
			if ! char
				@key_buff_i = 0_u8
			else
				if char == '\b' # ::X11::XK_BackSpace
					@key_buff_i -= 1 if @key_buff_i > 0
				elsif @hotstring_end_chars.includes?(char)
					@key_buff_i = 0_u8
					if ! prev_hotstring_candidate.nil?
						runner.set_global_built_in_static_var("A_EndChar", char.to_s)
						prev_hotstring_candidate.trigger
					end
				else
					@key_buff_i = 0_u8 if @key_buff_i > 29
					@key_buff[@key_buff_i] = char
					@key_buff_i += 1
					match = @hotstrings.find { |hs| hs.keysyms_equal?(@key_buff, @key_buff_i) }
					if match
						if match.immediate
							@key_buff_i = 0_u8
							runner.set_global_built_in_static_var("A_EndChar", "")
							match.trigger
						else
							@hotstring_candidate = match
						end
					end
				end
			end
		end
	end
end