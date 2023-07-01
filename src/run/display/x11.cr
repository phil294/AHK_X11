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
				# Hash lookups are expensive, they take about 3 ms each here (!) but I'm not really sure
				# we can do anything about it: NamedTuple would be much better for this use case as it's
				# stack-allocated and tailored towards values which are known at runtime, but it's
				# limited to 300 items only. I guess a solution would be a manually curated, reasonably
				# ordered list (perhaps case statement)... I now opted for adding a cache below, which
				# is definitely the fastest solution as the program runs over time (see _cache)
				.reduce({} of String => Int32) do |acc, const_name|
					key_name = const_name.stringify[3..]
					key_name = key_name.downcase if key_name.size > 1
					acc[key_name.gsub(/_/, "")] = const_name
					acc[key_name] = const_name
					acc
				end
		}}
	end
	# these are ahk-specific
	# List of x11 keysyms: lib/x11/src/x11/c/keysymdef.cr
	#   or https://github.com/xkbcommon/libxkbcommon/blob/master/include/xkbcommon/xkbcommon-keysyms.h
	# List of ahk key names: https://www.autohotkey.com/docs/v1/KeyList
	# TODO move out of x11.cr
	def self.ahk_key_name_to_keysym_custom
		{
			# Mouse

			# Could not find the constants for these. There most likely are none;
			# mouse buttons need special handling in the adapters so they can be treated like keys
			"lbutton" => 1,
			"rbutton" => 3,
			"mbutton" => 2,
			"xbutton1" => 8,
			"xbutton2" => 9,
			"wheeldown" => 5,
			"wheelup" => 4,
			"wheelleft" => 6, # [v1.0.48+]
			"wheelright" => 7, # [v1.0.48+]
			
			# Keyboard

			# General Keys
			"capslock" => XK_Caps_Lock,
			"space" => XK_space,
			"tab" => XK_Tab,
			"enter" => XK_Return,
			"return" => XK_Return,
			"escape" => XK_Escape,
			"esc" => XK_Escape,
			"backspace" => XK_BackSpace,
			"bs" => XK_BackSpace,

			# Cursor Control Keys
			"scrolllock" => XK_Scroll_Lock,
			"delete" => XK_Delete,
			"del" => XK_Delete,
			"insert" => XK_Insert,
			"ins" => XK_Insert,
			"home" => XK_Home,
			"end" => XK_End,
			"pgup" => XK_Page_Up,
			"pgdn" => XK_Page_Down,
			"up" => XK_Up,
			"down" => XK_Down,
			"left" => XK_Left,
			"right" => XK_Right,

			# Numpad Keys
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
			"numlock" => XK_Num_Lock,

			# Function Keys
			# FIXME: doesn't compile for some reason
			# {% for n in [1..24] %}
			# 	"F{{n}}" => XK_KP_F{{n}},
			# {% end %}

			# Modifier Keys
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

			# Multimedia Keys
			# These were determined either using `xev` or with https://github.com/qtile/qtile/blob/master/libqtile/backend/x11/xkeysyms.py (x11 must have them somewhere too??). TODO: These are mostly untested out of a lack of a fitting keyboard.
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

			# Other Keys
			"appskey" => XK_Menu,
			"printscreen" => XK_Print,
			"ctrlbreak" => XK_Break,
			"pause" => XK_Pause,
			"break" => XK_Pause,
			"help" => XK_Help,
			"sleep" => 0x1008FF2F, # XF86Sleep

			# Joystick
			# TODO


			# todo: outdated:
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
	class X11
		include DisplayAdapter
		# include ::X11 # removed because of https://github.com/TamasSzekeres/x11-cr/issues/15 and who knows what else. TODO

		@root_win = 0_u64
		@record_context : ::Xtst::LibXtst::RecordContext?
		@record : ::Xtst::RecordExtension?
		getter display : ::X11::Display
		getter root_win : ::X11::Window
		@x_do : XDo
		# Multiple threads can access this X11 instance, but to avoid dead locks surrounding
		# the blocking event loop, every state altering method needs to be synchronized with mutex:
		@mutex = Mutex.new

		def initialize(@x_do, xtest : Bool)
			set_error_handler

			@display = ::X11::Display.new
			@root_win = @display.root_window @display.default_screen_number

			if xtest
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
		end

		def finalize
			@mutex.lock
			@display.close
			@record.not_nil!.close if @record
		end

		# See comments inside `ahk_key_name_to_keysym_generic` for why this is necessary.
		# Esp. for stuff like `Input` with many EndKeys parameter, this cache is quite
		# useful, as it speed it up from 0.2s by factor 1,000
		@ahk_key_name_to_keysym_cache = {} of String => (Int32 | Bool)

		# TODO: unify with evdev? or better, only use evdev's implementation? but with cache
		private def ahk_key_name_to_keysym(key_name)
			return nil if key_name.empty?
			cached = @ahk_key_name_to_keysym_cache[key_name]?
			return cached if cached
			lookup = ::X11::C.ahk_key_name_to_keysym_custom[key_name]? || ::X11::C.ahk_key_name_to_keysym_generic[key_name]? || ::X11::C.ahk_key_name_to_keysym_custom[key_name.downcase]? || ::X11::C.ahk_key_name_to_keysym_generic[key_name.downcase]?
			if lookup
				@ahk_key_name_to_keysym_cache[key_name] = lookup
				return lookup
			end
			return nil if key_name.size > 1
			char = key_name[0]
			return nil if char >= 'A' && char < 'Z' || char >= 'a' && char <= 'z'
			# This fallback may fail but it's very likely this is the correct match now.
			# This is the normal path for special chars like . @ $ etc.
			ord = char.ord
			@ahk_key_name_to_keysym_cache[key_name] = ord
			ord
		end

		def key_combination_to_keysym(key_combo) : UInt64?
			key_name = key_combo.key_name
			if key_name.size == 1 && key_name.upcase != key_name.downcase && key_combo.modifiers.shift
				key_name = key_name.upcase
			end
			keysym = self.ahk_key_name_to_keysym(key_name)
			return nil if ! keysym || ! keysym.is_a?(Int32)
			keysym.to_u64
		end

		private def modifiers_to_modmask(modifiers)
			mask = 0_u8
			mask |= ::X11::ControlMask if modifiers.ctrl
			mask |= ::X11::ShiftMask   if modifiers.shift
			mask |= ::X11::Mod1Mask    if modifiers.alt
			mask |= ::X11::Mod4Mask    if modifiers.win
			mask |= ::X11::Mod5Mask    if modifiers.altgr
			mask
		end
		private def modmask_to_modifiers(mask)
			modifiers = KeyCombination::Modifiers.new
			modifiers.ctrl = true  if mask & ::X11::ControlMask == ::X11::ControlMask
			modifiers.shift = true if mask & ::X11::ShiftMask == ::X11::ShiftMask
			modifiers.alt = true   if mask & ::X11::Mod1Mask == ::X11::Mod1Mask
			modifiers.win = true   if mask & ::X11::Mod4Mask == ::X11::Mod4Mask
			modifiers.altgr = true if mask & ::X11::Mod5Mask == ::X11::Mod5Mask
			modifiers
		end

		def mouse_keysym_to_button(keysym)
			case keysym
			when 2 then XDo::Button::Middle
			when 3 then XDo::Button::Right
			when 4 then XDo::Button::ScrollUp
			when 5 then XDo::Button::ScrollDown
			when 6 then XDo::Button::ScrollLeft
			when 7 then XDo::Button::ScrollRight
			when 8 then XDo::Button::Button8
			when 9 then XDo::Button::Button9
			else XDo::Button::Left
			end
		end

		def key_combination_to_charcodemap(combo)
			
			# TODO: not very precise, is missing shift for @#$ etc.
			# this should probably work much differently
			# also bad because object modification but it's really only because of the current x11 logic
			# fixme: use evdev key lookup?
			if combo.key_name.size == 1 && combo.key_name.upcase != combo.key_name.downcase && ! combo.modifiers.shift && combo.key_name.upcase == combo.key_name
				combo.modifiers.shift = true
			end

			keysym = key_combination_to_keysym(combo)
			raise Run::RuntimeException.new "Key '#{combo.key_name}' not known" if ! keysym
			key_map = XDo::LibXDo::Charcodemap.new
			mouse_button : XDo::Button? = nil
			if keysym < 10
				# todo perhaps rm this function again and use the next bigger one?
				mouse_button = mouse_keysym_to_button(keysym)
			else
				key_map.code = @display.keysym_to_keycode(keysym)
				key_map.modmask = modifiers_to_modmask(combo.modifiers)
			end
			combo.repeat.times do
				if combo.down || ! combo.up
					yield [key_map], true, mouse_button
				end
				if combo.up || ! combo.down
					yield [key_map], false, mouse_button
				end
			end
		end

		def send(key_combos)
			@x_do.clear_active_modifiers @x_do.active_modifiers
			key_combos.each do |combo|
				key_combination_to_charcodemap(combo) do |key_map, pressed, mouse_button|
					if mouse_button
						if pressed
							@x_do.mouse_down mouse_button
						else
							@x_do.mouse_up mouse_button
						end
					else
						@x_do.keys_raw key_map, pressed: pressed, delay: 0
					end
				end
			end
		end

		def send_raw(text)
			@x_do.clear_active_modifiers @x_do.active_modifiers
			@x_do.type text
		end

		def mouse_move(thread, x : Int32?, y : Int32?, relative : Bool)
			x_current, y_current, screen = @x_do.mouse_location
			x ||= x_current
			y ||= y_current
			if relative
				@x_do.move_mouse x, y
			else
				if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
					x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x, y)
				end
				@x_do.move_mouse x, y, screen
			end
		end
		def mouse_pos : Tuple(UInt32, UInt32)
			x, y, _, _ = @x_do.mouse_location
			return x.to_u32, y.to_u32
		end
		def mouse_down(mouse_keysym : Int32)
			@x_do.mouse_down mouse_keysym_to_button(mouse_keysym)
		end
		def mouse_up(mouse_keysym : Int32)
			@x_do.mouse_up mouse_keysym_to_button(mouse_keysym)
		end

		def screen_width : UInt32
			@display.default_screen.width.to_u32
		end
		def screen_height : UInt32
			@display.default_screen.height.to_u32
		end

		# Makes sure the program doesn't exit when a Hotkey is not free for grabbing
		private def set_error_handler
			# Cannot use *any* outside variables here because any closure somehow makes set_error_handler never return, even with uninitialized (?why?), so we cannot set variables, show popup, nothing
			::X11.set_error_handler ->(display : ::X11::C::X::PDisplay, error_event : ::X11::C::X::PErrorEvent) do
				buffer = Array(UInt8).new 1024
				::X11::C::X.get_error_text display, error_event.value.error_code, buffer.to_unsafe, 1024
				error_message = String.new buffer.to_unsafe
				if error_event.value.error_code == 10
					STDERR.puts error_message + " (You can probably ignore this error)"
				else
					STDERR.puts "Display server unexpectedly failed with the following error message:\n\n#{error_message}\n\nThe script will exit."
					::exit 5
				end
				1
			end
		end

		@key_handler : Proc(KeyCombination, UInt64, Nil)?
		def run(*, key_handler)
			@key_handler = key_handler
			if record = @record
				record.enable_context_async(@record_context.not_nil!) do |record_data|
					handle_record_event(record_data)
				end
				record_fd = IO::FileDescriptor.new record.data_display.connection_number
				loop do
					# Although events from next_event aren't used in this case, this queue apparently
					# still must always be empty. If not, the hotkeys aren't even grabbed.
					flush_event_queue
					record_fd.not_nil!.wait_readable
					@mutex.lock
					record.process_replies
					@mutex.unlock
				end
			else
				# Misses non-grabbed keys and mouse events. It could also be done this way
				# (see old commits), but only unreliably and not worth the effort.
				loop do
					@mutex.lock
					event = @display.next_event # Blocking!
					@mutex.unlock
					if event.is_a? ::X11::KeyEvent
						handle_key_event(event)
					end
				end
			end
		end

		private def flush_event_queue
			@mutex.lock
			loop do
				break if @display.pending == 0
				@display.next_event
			end
			@mutex.unlock
		end

		private def handle_record_event(record_data)
			return if record_data.category != Xtst::LibXtst::RecordInterceptDataCategory::FromServer.value
			type, keycode, repeat = record_data.data
			state = record_data.data[28]
			if keycode < 9 # mouse button
				up = type == ::X11::ButtonRelease
				modifiers = modmask_to_modifiers(state)
				keysym = keycode.to_u64 # pretend so we can treat mouse and key uniquely
				@key_handler.not_nil!.call(KeyCombination.new("[mouse]", text: nil, modifiers: modifiers, up: up, down: !up, repeat: 1), keysym)
			else
				_key_event = ::X11::KeyEvent.new
				_key_event.display = @display
				_key_event.type = type
				_key_event.keycode = keycode
				_key_event.state = state
				handle_key_event(_key_event)
			end
		end

		private def handle_key_event(key_event)
			lookup = key_event.lookup_string
			char = lookup[:string][0]?
			keysym = lookup[:keysym]
			up = key_event.type == ::X11::KeyRelease || key_event.type == ::X11::ButtonRelease
			modifiers = modmask_to_modifiers(key_event.state)
			@key_handler.not_nil!.call(KeyCombination.new("[kbd]", text: char, modifiers: modifiers, up: up, down: !up, repeat: 1), keysym)
		end

		@@available_modifier_combinations : Array(Int32)
		# TODO: this can probably be done much easier, it's just all possible combinations of all possible sizes >= 1 of all relevant modifiers. Could actually also be a macro except that then you'd need the integers directly, not the X11 synonyms
		@@available_modifier_combinations =
			[1,2,3,4,5].reduce([] of Array(Int32)) do |all, i|
				[::X11::ControlMask, ::X11::ShiftMask, ::X11::Mod1Mask, ::X11::Mod4Mask, ::X11::Mod5Mask, ::X11::Mod2Mask].combinations(i).each do |mod_combo|
					all << mod_combo
				end
				all
			end.map &.reduce(0) do |all, v|
				all |= v
				all
			end
		def modifier_variants(hotkey)
			variants = [] of UInt32
			hotkey_modmask = modifiers_to_modmask(hotkey.modifiers)
			variants << hotkey_modmask
			variants << (hotkey_modmask | ::X11::Mod2Mask.to_u32)
			if hotkey.wildcard
				@@available_modifier_combinations.each do |other|
					if ! variants.includes? (hotkey_modmask | other)
						variants << (hotkey_modmask | other)
					end
				end
			end
			variants
		end
		def grab_hotkey(hotkey)
			@mutex.lock
			modifier_variants(hotkey).each do |mod|
				keysym = hotkey.keysym
				if keysym && keysym < 10
					@display.grab_button(keysym.to_u32, mod, grab_window: @root_win, owner_events: true, event_mask: ::X11::ButtonPressMask.to_u32, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync, confine_to: ::X11::None.to_u64, cursor: ::X11::None.to_u64)
				else
					@display.grab_key(@display.keysym_to_keycode(hotkey.keysym), mod, grab_window: @root_win, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync)
				end
			end
			@mutex.unlock
			flush_event_queue
		end
		def ungrab_hotkey(hotkey)
			@mutex.lock
			modifier_variants(hotkey).each do |mod|
				@display.ungrab_key(@display.keysym_to_keycode(hotkey.keysym), mod, grab_window: @root_win)
			end
			@mutex.unlock
			flush_event_queue
		end
		def grab_keyboard
			@mutex.lock
			@display.grab_keyboard(grab_window: @root_win, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync, time: ::X11::CurrentTime)
			@mutex.unlock
			flush_event_queue
		end
		def ungrab_keyboard
			@mutex.lock
			@display.ungrab_keyboard(time: ::X11::CurrentTime)
			@mutex.unlock
			flush_event_queue
		end
	end
end