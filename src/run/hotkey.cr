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

		@@available_modifier_combinations : Array(Int32)
		# TODO: this can probably be done much easier, it's just all possible combinations of all possible sizes >= 1 of all relevant modifiers. Could actually also be a macro except that then you'd need the integers directly, not the X11 synonyms
		@@available_modifier_combinations =
			[1,2,3,4,5].reduce([] of Array(Int32)) do |all, i|
				[::X11::ControlMask, ::X11::ShiftMask, ::X11::Mod1Mask, ::X11::Mod4Mask, ::X11::Mod5Mask, ::X11::Mod2Mask].combinations(i).each do |combo|
					all << combo
				end
				all
			end.map &.reduce(0) do |all, v|
				all |= v
				all
			end

		def init
			modifiers = 0_u32
			allow_other_modifiers = false
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
				when '*' then allow_other_modifiers = true
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
			if allow_other_modifiers
				@@available_modifier_combinations.each do |other|
					if ! @modifiers.includes? (modifiers | other)
						@modifiers << (modifiers | other)
					end
				end
			end
		end
		def trigger
			@runner.not_nil!.add_thread @cmd.not_nil!, @priority
		end
	end
end