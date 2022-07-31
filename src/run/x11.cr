require "x11"

at_exit { GC.collect }

module X11::C
	# Infer a long list of key names from lib/x11/src/x11/c/keysymdef.cr, stripped from XK_ and underscores
	private def self.ahk_key_name_to_keysym_generic
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
	private def self.ahk_key_name_to_keysym_custom
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
			# LButton - the left mouse button 
			# RButton - the right mouse button 
			# MButton - the middle or wheel mouse button 
			# WheelDown - this is equivalent to rotating the mouse wheel down (toward you) 
			# WheelUp - the opposite of the above 
			# Supported only in Windows XP/2000+:
			# XButton1 - a button that appears only on certain mice 
			# XButton2 - a button that appears only on certain mice 
			# all joystick buttons
			# Browser_Back
			# Browser_Forward
			# Browser_Refresh
			# Browser_Stop
			# Browser_Search
			# Browser_Favorites
			# Browser_Home
			# Volume_Mute
			# Volume_Down
			# Volume_Up
			# Media_Next
			# Media_Prev
			# Media_Stop
			# Media_Play_Pause
			# Launch_Mail
			# Launch_Media
			# Launch_App1
			# Launch_App2 
			# "special keys"
			# ctrlbreak
			# sleep
			# NumpadDiv - the slash key
			# NumpadMult - the asterisk key
			# NumpadAdd - the plus key
			# NumpadSub - the minus key
			# NumpadEnter - the Enter key 
			# The following keys are used when Numlock is OFF:
			# NumpadDel
			# NumpadIns
			# NumpadClear - same physical key as Numpad5 on most keyboards
			# NumpadUp
			# NumpadDown
			# NumpadLeft
			# NumpadRight
			# NumpadHome
			# NumpadEnd
			# NumpadPgUp
			# NumpadPgDn 
			# The following keys are used when Numlock is ON:
			# Numpad0
			# Numpad1
			# Numpad2
			# Numpad3
			# Numpad4
			# Numpad5
			# Numpad6
			# Numpad7
			# Numpad8
			# Numpad9
			# NumpadDot - the decimal point (period) key 
			# AppsKey - this is the key that invokes the right-click context menu. 
			# LWin - the left windows key 
			# RWin - the right windows key 
			# Control (or Ctrl) 
			# Alt
			# Shift 
			# Note: For the most part, these next 6 keys are not supported by Windows 95/98/Me. Use the above instead:
			# LControl (or LCtrl) - the left control key 
			# RControl (or RCtrl) - the right control key 
			# LShift
			# RShift
			# LAlt
			# RAlt -- Note: If your keyboard layout has AltGr instead of RAlt, you can probably use it as a hotkey prefix via <^>! as described here. In addition, "LControl & RAlt::" would make AltGr itself into a hotkey. 
		}
	end
	def self.ahk_key_name_to_keysym(key_name)
		ahk_key_name_to_keysym_generic[key_name]? ||
		ahk_key_name_to_keysym_custom[key_name]? ||
		nil
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
			keycode = @display.keysym_to_keycode(hotkey.keysym)
			@hotkey_subscriptions << {
				hotkey: hotkey,
				keycode: keycode
			}
			hotkey.modifiers.each do |mod|
				@display.grab_key(keycode, mod, grab_window: @root_win, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync)
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