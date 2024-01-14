require "x11"
require "xtst"
require "./display-adapter"

at_exit { GC.collect }

module X11::C
	# Infer a long list of key names from lib/x11/src/x11/c/keysymdef.cr, stripped from XK_ and underscores.
	# Seems to be necessary because XStringToKeysym is always case sensitive (?)
	# In our X11 key handling, we only deal with lowercase chars.
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
		# include ::X11 # removed because of https://github.com/TamasSzekeres/x11-cr/issues/15 and who knows what else. < TODO: is resolved

		@root_win = 0_u64
		@_NET_ACTIVE_WINDOW : ::X11::C::Atom
		@last_active_window = 0_u64
		# TODO: rename this var because name clash
		getter display : ::X11::Display
		getter root_win : ::X11::Window
		@x_do : XDo
		# Multiple threads can access this X11 instance, but to avoid dead locks surrounding
		# the blocking event loop, every state altering method needs to be synchronized with mutex:
		@mutex = Mutex.new
		@record_context : ::Xtst::LibXtst::RecordContext?
		@record : ::Xtst::RecordExtension?
		@runner : Run::Runner
		@grab_from_root : Bool

		def initialize(@runner, @x_do, xtest : Bool)
			::X11::C::X.init_threads # because otherwise crashes occur in some mysterious cases

			set_error_handler

			@display = ::X11::Display.new
			@root_win = @display.root_window @display.default_screen_number
			{% if ! flag?(:release) %}
				puts "[debug] x11: root_win = #{@root_win}"
			{% end %}
			@_NET_ACTIVE_WINDOW = @display.intern_atom("_NET_ACTIVE_WINDOW", true)
			{% if ! flag?(:release) %}
				puts "[debug] x11: _NET_ACTIVE_WINDOW = #{@_NET_ACTIVE_WINDOW}"
			{% end %}
			root_win_attributes = ::X11::SetWindowAttributes.new
			root_win_attributes.event_mask = ::X11::PropertyChangeMask
			# So we get notified of active window change
			@display.change_window_attributes(@root_win, ::X11::C::CWEventMask, root_win_attributes)
			@last_active_window = active_window()
			@grab_from_root = @runner.settings.x11_grab_from_root

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
					STDERR.puts "The script will continue but some features (esp. Hotstrings) may not work. Please also consider opening an issue at https://github.com/phil294/ahk_x11 and tell us about your system details."
				end
			end
		end

		private def active_window
			# TODO: manybe use @x_do.active_window if it's similarly fast? (evdev branch)
			return 0_u64 if @_NET_ACTIVE_WINDOW < 1
			prop = @display.window_property(@root_win, @_NET_ACTIVE_WINDOW, 0_i64, 1_i64, false, ::X11::C::XA_WINDOW.to_u64)
			nitems = prop[:nitems]
			data = prop[:prop].unsafe_as(Pointer(UInt64))
			if data.null? || nitems.nil? || nitems < 1
				{% if ! flag?(:release) %}
					puts "[debug] x11: active window detection: _NET_ACTIVE_WINDOW returned NULL prop data"
				{% end %}
				return 0_u64
			end
			win = data.value
			{% if ! flag?(:release) %}
				puts "[debug] x11: active window detection: #{win}"
			{% end %}
			win
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
			return nil if char >= 'A' && char <= 'Z' || char >= 'a' && char <= 'z'
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
					yield [key_map], true, mouse_button, combo
				end
				if combo.up || ! combo.down
					yield [key_map], false, mouse_button, combo
				end
			end
		end

		def send(thread, key_combos)
			hotkey = thread.hotkey
			# TODO: tests for all tweaks
			# TODO: recent fixes to send in x11 probably need to be added to evdev too
			active_modifiers = @x_do.active_modifiers
			# Clearing is *always* necessary, even if we want to keep the modifiers in blind mode, in which
			# case they are sent along yet again. Otherwise e.g. `^a::send {blind}b` fails. I don't know why.
			# Perhaps it's also only Ctrl that needs to be released once for Ctrl+x hotkeys to work, because
			# when I tested it, it didn't apply to Alt+x hotkeys.
			@x_do.clear_active_modifiers active_modifiers
			if hotkey && ! hotkey.no_grab
				active_modifiers.reject! do |mod|
					# We don't want to restore a modifier down below if it the hotkey *is* the modifier key.
					# This would essentially undo the grabbing.
					mod.code == hotkey.keycode
				end
			end
			# TODO:
			# Reactivate and test this commented out section once on evdev branch, then remove the
			# workaround applied further down (`blind = true`) because this properly replaces it
			# # # Triggered for both manual user's keypresses *while* the send happens (due to SetKeyDelay) and
			# # # the keys sent themselves below
			# # key_listener = thread.runner.display.register_key_listener do |key_event, keysym, char, is_paused|
			# # 	# this segfaults for no  fucking reason
			# # 	next if type != ::X11::KeyRelease
			# # 	modifier_key_up_index = active_modifiers.index do |mod|
			# # 		# v these are keysyms but would have to be key codes in order for the comparison to work
			# # 		[[::X11::XK_Control_L, ::X11::XK_Control_R], [::X11::XK_Shift_L, ::X11::XK_Shift_R], [::X11::XK_Alt_L, ::X11::XK_Alt_R]].index do |keys|
			# # 			(keys.index &.== mod.code) && (keys.index &.== key_code)
			# # 		end
			# # 	end
			# # 	if modifier_key_up_index
			# # 		# This modifier was released either by us (e.g. `Send, {Ctrl Up}`) or the user while
			# # 		# the sending took place, so it must not be pressed down again at the end with set_active_modifiers:
			# # 		active_modifiers.delete_at(modifier_key_up_index)
			# # 	end
			# # end
			# # ... further down: thread.runner.display.unregister_key_listener(key_listener)
			blind = nil
			key_combos.each do |combo|
				key_combination_to_charcodemap(combo) do |key_map, pressed, mouse_button|
					# Our parser allows for each char having their own `{blind}` modifier, but
					# the specs only allow it at the very start:
					if blind == nil
						blind = combo.blind
						if blind
							@x_do.set_active_modifiers active_modifiers
						end
					end
					if mouse_button
						if pressed
							@x_do.mouse_down mouse_button
						else
							@x_do.mouse_up mouse_button
						end
					else
						if hotkey && combo.keysym == hotkey.keysym && thread.runner.display.pressed_keys.includes?(combo.keysym)
							# https://github.com/jordansissel/xdotool/issues/210 (see also hotkeys.cr)
							# Not a super great solution because for every key up/down combo of the hotkey, this will
							# *always* send a second key up event now, but oh well it works
							# TODO: only do this once
							hotkey_key_up = XDo::LibXDo::Charcodemap.new
							hotkey_key_up.code = hotkey.keycode
							@x_do.keys_raw [hotkey_key_up], pressed: false, delay: 0
						end
						if [::X11::XK_Control_L, ::X11::XK_Control_R, ::X11::XK_Shift_L, ::X11::XK_Shift_R, ::X11::XK_Alt_L, ::X11::XK_Alt_R].includes?(combo.keysym)
							# TODO: this is just a workaround so that e.g. `Send, {Ctrl up}` doesn't fail due to
							# the `set_active_modifiers` at the end. Rework this once on evdev branch (s. above).
							blind = true
						end
						@x_do.keys_raw key_map, pressed: pressed, delay: 0
					end
					if pressed
						sleep thread.settings.key_press_duration.milliseconds if thread.settings.key_press_duration > -1
					else
						sleep thread.settings.key_delay.milliseconds if thread.settings.key_delay > -1
					end
				end
			end
			if ! blind
				# We can't use `x_do.set_active_modifiers active_modifiers` here like above because while it would be
				# the preferred method, it also does some `xdo_mouse_down()` internally, based on current input state.
				# And when we've sent an `{LButton}` down+up event in the keys, the x11 server might still report for the button
				# to be pressed down when the up event hasn't been processed yet by it, resulting in wrong input state and
				# effectively a wrong button pressed again by libxdo.
				@x_do.keys_raw active_modifiers, pressed: true, delay: 0
			end
		end

		def send_raw(thread, text)
			active_modifiers = @x_do.active_modifiers
			@x_do.clear_active_modifiers active_modifiers
			hotkey = thread.hotkey
			# TODO: duplicate code as in send.cr
			if hotkey && ! hotkey.no_grab
				active_modifiers.reject! do |mod|
					# We don't want to restore a modifier down below if it the hotkey *is* the modifier key.
					# This would essentially undo the grabbing.
					mod.code == hotkey.keycode
				end
			end
			if (hotkey = thread.hotkey) && hotkey.key_name.size == 1 && txt.includes?(hotkey.key_name)
				# TODO: duplicate code as in send()
				key_map_hotkey_up = XDo::LibXDo::Charcodemap.new
				key_map_hotkey_up.code = hotkey.keycode
				@x_do.keys_raw [key_map_hotkey_up], pressed: false, delay: 0
			end
			@x_do.type txt
			@x_do.set_active_modifiers active_modifiers
		end

		# speed is fixed to instantaneously and cannot be altered
		def mouse_move(thread, x : Int32?, y : Int32?, relative : Bool)
			# Regarding speed: In Win AHK, speed is realized by moving the mouse step-wise,
			# with each step being 32px in w/h at least (but also somehow it works differently?!)
			# https://github.com/AutoHotkey/AutoHotkey/blob/e18a857e2d6d57d73643fbdd57d739a88ea499e5/source/keyboard_mouse.cpp#L2330
			# https://github.com/AutoHotkey/AutoHotkey/blob/c1f20dc8846ccad4dc54d3a1e69f39449c6ea1dc/source/script_autoit.cpp#L1828-L1888
			# For Linux, libxdo doesn't offer steps yet:
			# https://github.com/jordansissel/xdotool/blob/98a33e4ed1ae3753bcb20924dd6cdfa563331079/cmd_mousemove.c#L208
			# We can't take simulate the steps in Crystal code here because that would be too slow
			# (every xdo request takes ~30ms itself already). So a PR to xdotool implementing steps
			# would be necessary.
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
					# Grabbing failed, most likely because already grabbed by other program / script instance
					STDERR.puts error_message + " (You can probably ignore this error)"
				else
					STDERR.puts "Display server unexpectedly failed with the following error message:\n\n#{error_message}\n\nThe script will exit."
					::exit 5
				end
				1
			end
		end

		@key_handler : Proc(KeyCombination, UInt64, Nil)?
		@flush_event_queue = Channel(Nil).new
		def run(*, key_handler)
			@key_handler = key_handler
			record = @record
			if record
				spawn same_thread: true do
					record.enable_context_async(@record_context.not_nil!) do |record_data|
						handle_record_event(record_data)
					end
					record_fd = IO::FileDescriptor.new record.data_display.connection_number
					loop do
						record_fd.not_nil!.wait_readable
						@mutex.lock
						record.process_replies
						@mutex.unlock
					end
				end
			end
			# Even if XTst Record obliterates the need to read key events, we still need to
			# keep the event loop running or otherwise the hotkeys aren't even grabbed
			# and use it to get updates on the active window.
			spawn same_thread: true do
				event_fd = IO::FileDescriptor.new @display.connection_number
				loop do
					# Instead of this, running `next_event` (blocking) in a loop also works but requires a separate thread.
					# But that somehow messes up `::exit` so we don't do that.
					# This very solution, `wait_readable`, has shown to *sometimes* be unreliable, i.e. hotkeys aren't
					# grabbed properly because some pending events somehow aren't visible. To solve this,
					# `flush_event_queue` is also called from a few other places.
					event_fd.wait_readable
					@flush_event_queue.send(nil)
				end
			end
			loop do
				while @display.pending != 0
					@mutex.lock
					event = @display.next_event
					if event.is_a?(::X11::PropertyEvent) && event.atom == @_NET_ACTIVE_WINDOW
						# focussed_win = @display.input_focus[:focus] # https://stackoverflow.com/q/31800880, https://stackoverflow.com/q/60141048
						active_win = active_window()
						if active_win != @last_active_window && active_win > 0
							active_window_before = @last_active_window
							@last_active_window = active_win
							if ! @grab_from_root
								# The mutex doesn't protect against nonsense here yet but the chance for
								# this to happen is fairly small
								spawn same_thread: true do
									@hotkeys.each { |h| ungrab_hotkey(h, from_window: active_window_before, unsubscribe: false) }
									@hotkeys.each { |h| grab_hotkey(h, subscribe: false) }
								end
							end
						end
					end
					@mutex.unlock
					if ! record
						# Misses non-grabbed keys and mouse events. It could also be done this way
						# (see old commits), but only unreliably and not worth the effort.
						if event.is_a? ::X11::KeyEvent
							handle_key_event(event)
						end
					end
				end
				@flush_event_queue.receive
			end
		end

		# todo repeat? see prev commit here
		private def handle_record_event(record_data)
			return if record_data.category != Xtst::LibXtst::RecordInterceptDataCategory::FromServer.value
			type, keycode, repeat = record_data.data
			state = record_data.data[28]
			if type >= 4 # mouse button. keycode will be 1-9
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
			state_bck = key_event.state
			# We want to receive a usable char even when e.g. Ctrl is pressed, currently only
			# because of the shift/uppercase detection below. Shift needs to stay in state though
			# to differentiate e.g. 2 vs @ and mod2 = num lock for num numbers # TODO < add auto num number hotkey test
			key_event.state = key_event.state & (::X11::ShiftMask | ::X11::Mod2Mask)
			lookup = key_event.lookup_string
			key_event.state = state_bck
			char = lookup[:string][0]?
			keysym = lookup[:keysym]
			# We may have e.g. grabbed *a (so including Shift + lowercase a) but the reported
			# event here will return Shift + uppercase A. We'll deal with lowercase only.
			if char && char.downcase != char
				char = char.downcase
				keysym = Run::X11.ahk_key_name_to_keysym(char.to_s)
				# TODO: like ahk-string.cr
				raise Run::RuntimeException.new "Unexpected keysym #{keysym} is uppercase but can't be mapped to lowercase" if ! keysym || ! keysym.is_a?(Int32)
			end
			up = key_event.type == ::X11::KeyRelease || key_event.type == ::X11::ButtonRelease
			modifiers = modmask_to_modifiers(key_event.state)
			@key_handler.not_nil!.call(KeyCombination.new("[kbd]", text: char, modifiers: modifiers, up: up, down: !up, repeat: 1), keysym)
		end

		private def grab_window
			# Last can be 0 in rare cases such as on Solus KDE after hotkey press of *other* script
			# without grab_from_root set
			if @grab_from_root || @last_active_window == 0
				@root_win
			else
				@last_active_window
			end
		end

		@@available_modifier_combinations : Array(Int32)
		# TODO: this can probably be done much easier, it's just all possible combinations of all possible sizes >= 1 of all relevant modifiers. Could actually also be a macro except that then you'd need the integers directly, not the X11 synonyms
		@@available_modifier_combinations =
			[1,2,3,4,5].reduce([] of Array(Int32)) do |all, i|
				# ctrl, shift, 1=alt, 4=super, 5=altgr, 2=numlock
				[::X11::ControlMask, ::X11::ShiftMask, ::X11::Mod1Mask, ::X11::Mod4Mask, ::X11::Mod5Mask, ::X11::Mod2Mask].combinations(i).each do |mod_combo|
					all << mod_combo
				end
				all
			end.map &.reduce(0) do |all, v|
				all |= v
				all
			end
		# In X11, numlock is a modifier (Mod2Mask) that always needs to be included in the grab
		# variations, as X11 sees e.g. A as a different hotkey than NumLock+A.
		# However, for the keys positioned on the Numpad block itself, this generalization
		# does not apply as the functionality (keycode) indeed depends on the state of NumLock.
		# - Num0 to 9 and dot/comma require NumLock OFF
		# - NumIns, Del, Home etc. require NumLock ON
		# - NumEnter, Add, Sub, Del, Mult keysyms normally don't care for NumLock state except
		#   on very rare keyboards where they will instead map to Equals, Zoom, Copy etc.
		#   For our purposes, this doesn't matter, as per AHK spec, the latter keys don't exist.
		# TODO: what about evdev?
		private def is_numpad_with_numlock_only(keysym)
			keysym == ::X11::XK_KP_0 || keysym == ::X11::XK_KP_1 || keysym == ::X11::XK_KP_2 || keysym == ::X11::XK_KP_3 || keysym == ::X11::XK_KP_4 || keysym == ::X11::XK_KP_5 || keysym == ::X11::XK_KP_6 || keysym == ::X11::XK_KP_7 || keysym == ::X11::XK_KP_8 || keysym == ::X11::XK_KP_9 ||
			# Grabbing this one somehow doesn't seem to work, although the key detection etc. is fine
			keysym == ::X11::XK_KP_Decimal
			# || keysym == ::X11::XK_KP_Separator # doesn't exist in AHK
			# Always active, see above:
			# || ::X11::XK_KP_Multiply || keysym == ::X11::XK_KP_Add || keysym == ::X11::XK_KP_Subtract || keysym == ::X11::XK_KP_Divide || keysym == ::X11::XK_KP_Enter
		end
		# :ditto:
		private def is_numpad_without_numlock_only(keysym)
			keysym == ::X11::XK_KP_Home || keysym == ::X11::XK_KP_Left || keysym == ::X11::XK_KP_Up || keysym == ::X11::XK_KP_Right || keysym == ::X11::XK_KP_Down || keysym == ::X11::XK_KP_Page_Up || keysym == ::X11::XK_KP_Page_Down || keysym == ::X11::XK_KP_End || keysym == ::X11::XK_KP_Begin || keysym == ::X11::XK_KP_Insert || keysym == ::X11::XK_KP_Delete
			# Don't exist in AHK:
			# || ::X11::XK_KP_Space || keysym == ::X11::XK_KP_Tab || keysym == ::X11::XK_KP_F1 || keysym == ::X11::XK_KP_F2 || keysym == ::X11::XK_KP_F3 || keysym == ::X11::XK_KP_F4 || keysym == ::X11::XK_KP_Prior || keysym == ::X11::XK_KP_Next || keysym == ::X11::XK_KP_Equal
		end
		# todo rename
		def modifier_variants(hotkey)
			variants = [] of UInt32
			hotkey_modmask = modifiers_to_modmask(hotkey.modifiers)
			variants << hotkey_modmask if ! is_numpad_with_numlock_only(hotkey.keysym)
			variants << (hotkey_modmask | ::X11::Mod2Mask.to_u32) if ! is_numpad_without_numlock_only(@keysym)
			if hotkey.wildcard
				@@available_modifier_combinations.each do |other|
					if ! variants.includes? (hotkey_modmask | other)
						variants << (hotkey_modmask | other)
					end
				end
			end
			variants
		end
		# It's easier to just grab on the root window once, but by repeatedly reattaching to the respectively currently
		# active window, we avoid losing focus from the active window while a grabbed key is pressed down.
		# https://stackoverflow.com/a/69216578/3779853
		# This helps avoiding various popups and menus from auto-closing on hotkey press.
		# Because of this, this driver needs to maintain its own list of hotkeys.
		# This behavior depends on `@grab_from_root`.
		@hotkeys = [] of Hotkey
		# :ditto:
		def grab_hotkey(hotkey, *, subscribe = true)
			@mutex.lock
			@hotkeys << hotkey if subscribe && hotkey.keysym >= 10
			modifier_variants(hotkey).each do |mod|
				keysym = hotkey.keysym
				if keysym && keysym < 10
					@display.grab_button(keysym.to_u32, mod, grab_window: @root_win, owner_events: true, event_mask: ::X11::ButtonPressMask.to_u32, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync, confine_to: ::X11::None.to_u64, cursor: ::X11::None.to_u64)
				else
					@display.grab_key(@display.keysym_to_keycode(hotkey.keysym), mod, grab_window: grab_window, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync)
				end
			end
			@mutex.unlock
			@flush_event_queue.send(nil)
		end
		# :ditto:
		def ungrab_hotkey(hotkey, *, from_window = @last_active_window, unsubscribe = true)
			# todo ungrab_button??
			@mutex.lock
			@hotkeys.delete hotkey if unsubscribe
			modifier_variants(hotkey).each do |mod|
				if hotkey.keysym < 10
					@display.ungrab_button(hotkey.keysym, mod, grab_window: @root_win)
				else
					@display.ungrab_key(@display.keysym_to_keycode(hotkey.keysym), mod, grab_window: @grab_from_root ? @root_win : from_window)
				end
			end
			@mutex.unlock
			@flush_event_queue.send(nil)
		end
		def grab_keyboard
			@mutex.lock
			@display.grab_keyboard(grab_window: grab_window, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync, time: ::X11::CurrentTime)
			@mutex.unlock
			@flush_event_queue.send(nil)
		end
		def ungrab_keyboard
			@mutex.lock
			@display.ungrab_keyboard(time: ::X11::CurrentTime)
			@mutex.unlock
			@flush_event_queue.send(nil)
		end
		def grab_pointer
			@mutex.lock
			@display.grab_pointer(grab_window: grab_window, owner_events: true, pointer_mode: ::X11::GrabModeAsync, keyboard_mode: ::X11::GrabModeAsync, time: ::X11::CurrentTime, event_mask: 0_u32, confine_to: 0_u64, cursor: 0_u64)
			@mutex.unlock
			@flush_event_queue.send(nil)
		end
		def ungrab_pointer
			@mutex.lock
			@display.ungrab_pointer(time: ::X11::CurrentTime)
			@mutex.unlock
			@flush_event_queue.send(nil)
		end

		def show_desktop(show)
			_NET_SHOWING_DESKTOP = @display.intern_atom("_NET_SHOWING_DESKTOP", false)
    		event = ::X11::ClientMessageEvent.new
			event.type = ::X11::C::ClientMessage
    		event.window = @root_win
    		event.message_type = _NET_SHOWING_DESKTOP
    		event.format = 32
			value = show ? 1_i64 : 0_i64
			event.long_data = StaticArray[value, 0_i64, 0_i64, 0_i64, 0_i64]
			@display.send_event(@root_win, false, ::X11::C::SubstructureRedirectMask | ::X11::C::SubstructureNotifyMask, event)
			display.flush # <- I DON'T KNOW WHY BUT I WANT MY THREE HOURS BACK
		end
	end
end