require "evdev"
require "./libxkbcommon"

# A normal Evdev::Device but it keeps track of the key presses so that we can look up
# sym by code based on internal state.
class Run::StatefulDevice < ::Evdev::Device
	protected property state : LibXKBCommon::State
	getter modifiers = KeyCombination::Modifiers.new

	# Some of the duplication in this file is necessary because parent self.from_file is static and not inheritable.
	def self.from_file(file : IO::FileDescriptor, keymap : LibXKBCommon::Keymap)
		if LibEvdev.new_from_fd(file.fd, out dev) < 0
			raise ::Evdev::Error.from_errno
		end
		new(dev, keymap)
	end
	def self.new(keymap : LibXKBCommon::Keymap)
		new(LibEvdev.new, keymap)
	end
	private def initialize(@device : LibEvdev::Device, keymap : LibXKBCommon::Keymap)
		raise ::Evdev::Error.from_errno if @device.null?
		@state = LibXKBCommon.state_new(keymap)
	end
	def initialize(keymap : LibXKBCommon::Keymap)
		@device = LibEvdev.new
		@state = LibXKBCommon.state_new(keymap)
	end

	def finalize
		LibXKBCommon.state_free(@state)
	end

	def next_event(flags)
		event, status = super(flags)
		direction = LibXKBCommon::KeyDirection.new(event.value)
		LibXKBCommon.state_update_key(@state, event.code + 8, direction)
		update_modifiers(event.code, direction)
		return event, status
	end

	private def update_modifiers(code, direction)
		value = direction == LibXKBCommon::KeyDirection::Down
		case code
		when ::Evdev::Codes::Key::Leftctrl, ::Evdev::Codes::Key::Rightctrl
			@modifiers.ctrl  = value
		when ::Evdev::Codes::Key::Leftshift, ::Evdev::Codes::Key::Rightshift
			@modifiers.shift = value
		when ::Evdev::Codes::Key::Leftalt
			@modifiers.alt   = value
		when ::Evdev::Codes::Key::Leftmeta, ::Evdev::Codes::Key::Rightmeta
			@modifiers.win   = value
		when ::Evdev::Codes::Key::Rightalt
			@modifiers.altgr = value
		end
	end

	def evdev_code_to_evdev_keysym(code : ::Evdev::Codes::All)
		keysym = LibXKBCommon.state_key_get_sym(@state, code + 8)
		# This bit is specific to AHK_X11 because we want to treat mouse buttons and keyboard keys equally
		if keysym == 0
			keysym = case code
			# todo include codes somewhere to skip ::evdev stuff everywhere in this file and also evdev.cr etc
			when ::Evdev::Codes::Key::BtnLeft then 1_u32
			when ::Evdev::Codes::Key::BtnRight then 3_u32
			when ::Evdev::Codes::Key::BtnMiddle then 2_u32
			when ::Evdev::Codes::Key::BtnSide then 8_u32
			when ::Evdev::Codes::Key::BtnExtra then 9_u32
			else
				raise "unexpected evdev event code '#{code.type}/#{code}' with keysym 0"
			end
		end
		keysym
	end
	def evdev_keysym_to_char(sym : LibXKBCommon::KeysymT)
		LibXKBCommon.keysym_to_utf32(sym).unsafe_chr
	end
	def evdev_code_to_char(code : ::Evdev::Codes::All)
		evdev_keysym_to_char(evdev_code_to_evdev_keysym(code))
	end

	protected def iter(keymap, &cb : UInt32 ->)
		LibXKBCommon.keymap_for_each(keymap, ->(map, key, data) {
			Box(typeof(cb)).unbox(data).call(key)
		}, Box.box(cb))
	end
end