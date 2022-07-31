module Run
	class Hotkey
		property runner : Run::Runner?
		getter key_str : String
		property cmd : Cmd::Base?
		property priority : Int32
		property active = true
		getter modifiers = [] of UInt32
		getter keysym = 0_u64
		getter no_grab = false
		def initialize(@key_str, *, @priority)
			init
		end
		def initialize(@runner, @cmd, @key_str, *, @priority, @active = true)
			init
		end
		def init
			modifiers = 0_u32
			key_name = ""
			str = @key_str.sub("<^>!", "\0")
			str.each_char_with_index do |char, i|
				case char
				when '^' then modifiers |= ::X11::ControlMask
				when '+' then modifiers |= ::X11::ShiftMask
				when '!' then modifiers |= ::X11::Mod1Mask
				when '#' then modifiers |= ::X11::Mod4Mask
				when '\0' then modifiers |= ::X11::Mod5Mask
				when '~' then @no_grab = true # INCOMPAT: will then not work in some windows
				else
					key_name = str[i..]
					break
				end
			end
			keysym = ::X11::C.ahk_key_name_to_keysym(key_name)
			raise RuntimeException.new "Hotkey key name '#{key_name}' not found." if ! keysym || ! keysym.is_a?(Int32)
			@keysym = keysym.to_u64
			@modifiers << modifiers
			@modifiers << (modifiers | ::X11::Mod2Mask.to_u32)
		end
		def trigger
			@runner.not_nil!.add_thread @cmd.not_nil!, @priority
		end
	end
end