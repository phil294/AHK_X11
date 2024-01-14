require "evdev"
require "./display-adapter"
require "./stateful-device"
require "./keyboard-layout"
require "./key-lookup"

module Run
	class Evdev
		include DisplayAdapter

		@key_lookup : KeyLookup
		# FIXME & comments in file
		@mutex = Mutex.new

		@devices = [] of StatefulDevice
		@uinput : ::Evdev::UinputDevice?
		def initialize(@key_lookup, keymap)
			Dir.glob("/dev/input/event*") do |path|
				file = File.open(path)
				device = StatefulDevice.from_file(file, keymap)
				if is_interesting_device(device)
					file.close_on_finalize = false
					@devices << device
				else
					file.close
				end
			end
			# fixme: allow grabbing keys: possible with https://github.com/gvalkov/python-evdev/issues/3
			uinput_device = ::Evdev::Device.new
			uinput_device.name = "AHK_X11 virtual input device"
			# The activation of all codes takes ~300ms. Is there a better way?
			# It's possible to reuse an existing device but that wouldn't have all required codes
			# TODO: narrow down?
			# ::Evdev::Codes::Abs
			[::Evdev::Codes::Key, ::Evdev::Codes::Rel].each do |type|
				type.each do |code|
					uinput_device.enable_event_code(code)
				end
			end
			@uinput = ::Evdev::UinputDevice.new(uinput_device)
			@screen_width_cached = screen_width
			@screen_height_cached = screen_height
		end

		@mouse_x = 0_u32
		@mouse_y = 0_u32
		def mouse_pos : Tuple(UInt32, UInt32)
			return @mouse_x, @mouse_y
		end
		def screen_width : UInt32
			`cat /sys/class/graphics/fb0/virtual_size`.split(',')[0].to_u32
		end
		def screen_height : UInt32
			`cat /sys/class/graphics/fb0/virtual_size`.split(',')[1].to_u32
		end
		@screen_width_cached : UInt32
		@screen_height_cached : UInt32
		private def mouse_x_add(x)
			@mouse_x = Math.min(@screen_width_cached, Math.max(0, @mouse_x.to_i + x)).to_u32
		end
		private def mouse_y_add(y)
			@mouse_y = Math.min(@screen_height_cached, Math.max(0, @mouse_y.to_i + y)).to_u32
		end

		# Adapted from the official example at
		# https://github.com/xkbcommon/libxkbcommon/blob/5b5ec0ee2781fb540c60f7f554787cef1e2aaa87/tools/interactive-evdev.c#L91
		private def is_interesting_device(device)
			return true if device.has_event_code?(::Evdev::Codes::Rel::Wheel)
			return false if ! device.has_event_type?(::Evdev::EventType::Key)
			[(::Evdev::Codes::Key::Reserved.value..::Evdev::Codes::Key::Mute.value),
			(::Evdev::Codes::Key::BtnMouse.value..::Evdev::Codes::Key::BtnThumbr.value)]
			.each do |range|
				range.each do |key|
					return true if device.has_event_code?(::Evdev::Codes::Key.new(key))
				end
			end
			false
		end

		def finalize
			@mutex.lock
		end

		# @@ahk_key_name_to_keysym_cache = {} of String => (Int32 | Bool)

		@key_handler : Proc(KeyCombination, UInt64, Nil)?
		def run(*, key_handler)
			@key_handler = key_handler

			device_channel = Channel(StatefulDevice).new
			# TODO; chatgpt suggested this instead:
			# ready = IO.select([device.fd], nil, nil, 0.1)
			@devices.each do |device|
				fd = IO::FileDescriptor.new(device.fd)
				spawn same_thread: true do
					loop do
						fd.wait_readable
						device_channel.send(device)
					end
				end
			end
			loop do
				# @mutex.lock
				device = device_channel.receive
				# @mutex.unlock
				while device.event_pending?
					event, status = device.next_event(LibEvdev::ReadFlags::Normal)
					if event.code.type == ::Evdev::EventType::Key || event.code == ::Evdev::Codes::Rel::Wheel
						keysym = device.evdev_code_to_evdev_keysym(event.code)
						char = device.evdev_keysym_to_char(keysym)
						# down is 1, repeat is 2, so repetition events are seen as key down events. TODO: same as in win ahk?
						up = event.value == 0
						currently_pressed_modifiers = device.modifiers
						@key_handler.not_nil!.call(KeyCombination.new("[kbd]", text: char, modifiers: currently_pressed_modifiers, up: up, down: !up, repeat: 1), keysym.to_u64)
					elsif event.code == ::Evdev::Codes::Rel::X
						mouse_x_add(event.value)
					elsif event.code == ::Evdev::Codes::Rel::Y
						mouse_y_add(event.value)
					end
				end
			end
		end

		private def modifiers_to_keys(modifiers)
			keys = [] of ::Evdev::Codes::Key
			keys << ::Evdev::Codes::Key::Leftctrl  if modifiers.ctrl
			keys << ::Evdev::Codes::Key::Leftshift if modifiers.shift
			keys << ::Evdev::Codes::Key::Leftalt   if modifiers.alt
			keys << ::Evdev::Codes::Key::Leftmeta  if modifiers.win
			keys << ::Evdev::Codes::Key::Rightalt  if modifiers.altgr
			keys
		end

		def key_combination_to_keysym(key_combo) : UInt64?
			key_name_to_keysym(key_combo.key_name)
		end
		def key_name_to_keysym(key_name)
			if key_name.size == 1
				@key_lookup.char_to_evdev_keysym(key_name[0]).to_u64
			else
				# code = @@ahk_key_name_to_evdev_code_custom[key_name]
				# TODO test
				sym = ::X11::C.ahk_key_name_to_keysym_custom[key_name.downcase]?
				sym ? sym.to_u64 : nil
			end
		end

		def send(thread, key_combos)
			uinput = @uinput.not_nil!
			key_combos.each do |combo|
				keysym = key_combination_to_keysym(combo)
				raise Run::RuntimeException.new "Key '#{combo.key_name}' not known" if ! keysym
				combo.repeat.times do
					# WheelUp/Down is the only thing that can't be sent as a normal key because it's from the REL subgroup
					# TODO: scroll left / right is pbly broken for both sending and hotkeys
					if keysym == 4 || keysym == 5
						uinput.write_event(::Evdev::Codes::Rel::Wheel, keysym == 4 ? 1 : -1)
						uinput.write_event(::Evdev::Codes::Syn::Report, 0)
					else
						# includes modifiers for key_name itself based on keyboard layout, e.g.
						# {SHIFT} and {a} for A or ! as opposed to a or 1
						key_codes_for_key = @key_lookup.evdev_keysym_to_evdev_codes(keysym.to_u32)
						# TODO test
						raise IndexError.new "key name '#{combo.key_name}' not found" if ! key_codes_for_key
						# includes modifiers for the key specified by ahk syntax, e.g.
						# ALT for ! or CTRL for ^
						key_codes_for_modifiers = modifiers_to_keys(combo.modifiers)
						keys = key_codes_for_modifiers + key_codes_for_key
						if combo.down || ! combo.up
							# TODO: keep track of mods already pressed before so to restore to what it was before
							keys.each do |key|
								puts "SEND DOWN", key
								uinput.write_event(key, LibXKBCommon::KeyDirection::Down)
							end
							uinput.write_event(::Evdev::Codes::Syn::Report, 0)
						end
						if combo.up || ! combo.down
							keys.reverse.each do |key|
								puts "SEND UP", key
								uinput.write_event(key, LibXKBCommon::KeyDirection::Up)
							end
							uinput.write_event(::Evdev::Codes::Syn::Report, 0)
						end
					end
				end
			end
		end

		def send_raw(thread, text)
			uinput = @uinput.not_nil!
			text.each_char do |char|
				keysym = key_name_to_keysym(char.to_s)
				raise Run::RuntimeException.new "Key '#{char}' not known" if ! keysym
				keys = @key_lookup.evdev_keysym_to_evdev_codes(keysym.to_u32)
				# TODO test (s.a. above)
				raise IndexError.new "char '#{char}' not found" if ! keys
				# TODO: keep track of mods already pressed before so to restore to what it was before
				# todo combine logic with @send() and mouse_down/up, into a more generic send function
				keys.each do |key|
					puts "SEND DOWN", key
					uinput.write_event(key, LibXKBCommon::KeyDirection::Down)
				end
				uinput.write_event(::Evdev::Codes::Syn::Report, 0)
				keys.reverse.each do |key|
					puts "SEND UP", key
					uinput.write_event(key, LibXKBCommon::KeyDirection::Up)
				end
				uinput.write_event(::Evdev::Codes::Syn::Report, 0)
			end
		end

		def mouse_move(thread, x : Int32?, y : Int32?, relative : Bool)
			# TODO:
			# if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
			# 	raise Run::RuntimeException.new "MoussdfffffffffffdddddasdfasdfqsdfeClick coordinates can (currently?) only be used with absolute CoordMode (screen) on non-X11 systems like your seems to be"
			uinput = @uinput.not_nil!
			if ! relative
				# no actual relative positioning possible (evdev is just a stream of device events and knows
				# nothing about the screen(s)), so we emulate that by going up/left a lot first.
				# Some window managers can apparently limit the maximum offset so several attempts are being made.
				uinput.write_event(::Evdev::Codes::Rel::X, -100000)
				uinput.write_event(::Evdev::Codes::Rel::Y, -100000)
				uinput.write_event(::Evdev::Codes::Syn::Report, 0)
				10.times do
					uinput.write_event(::Evdev::Codes::Rel::X, -500)
					uinput.write_event(::Evdev::Codes::Rel::Y, -500)
					uinput.write_event(::Evdev::Codes::Syn::Report, 0)
				end
				@mouse_x = 0_u32
				@mouse_y = 0_u32
			end
			x ||= 0
			y ||= 0
			uinput.write_event(::Evdev::Codes::Rel::X, x)
			uinput.write_event(::Evdev::Codes::Rel::Y, y)
			uinput.write_event(::Evdev::Codes::Syn::Report, 0)
			mouse_x_add(x)
			mouse_y_add(y)
		end
		def mouse_down(mouse_keysym : Int32)
			uinput = @uinput.not_nil!
			keys = @key_lookup.evdev_keysym_to_evdev_codes(mouse_keysym.to_u32)
			keys.each do |key|
				uinput.write_event(key, LibXKBCommon::KeyDirection::Down)
			end
			uinput.write_event(::Evdev::Codes::Syn::Report, 0)
		end
		def mouse_up(mouse_keysym : Int32)
			# TODO code duplication
			uinput = @uinput.not_nil!
			keys = @key_lookup.evdev_keysym_to_evdev_codes(mouse_keysym.to_u32)
			keys.each do |key|
				uinput.write_event(key, LibXKBCommon::KeyDirection::Up)
			end
			uinput.write_event(::Evdev::Codes::Syn::Report, 0)
		end

		# doesn't seem to be possible with evdev (?) todo
		def grab_hotkey(hotkey)
		end
		def ungrab_hotkey(hotkey)
		end

		# todo rename to block_input
		def grab_keyboard
			@mutex.lock
			@devices.each &.grab(LibEvdev::GrabMode::Grab)
			@mutex.unlock
		end
		def ungrab_keyboard
			@mutex.lock
			@devices.each &.grab(LibEvdev::GrabMode::Ungrab)
			@mutex.unlock
		end
	end
end