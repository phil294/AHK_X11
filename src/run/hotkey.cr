require "./key-combination"

module Run
	class Hotkey < KeyCombination
		property runner : Run::Runner?
		getter key_str : String
		property cmd : Cmd::Base?
		property priority : Int32
		property active = true
		getter modifier_variants = [] of UInt32
		getter no_grab = false
		property exempt_from_suspension = false
		def initialize(@key_str, *, @priority, escape_char)
			init(escape_char)
		end
		def initialize(@runner, @cmd, @key_str, *, @priority, escape_char, @active = true)
			init(escape_char)
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

		def init(escape_char)
			key_combos = Util::AhkString.parse_key_combinations(@key_str.gsub("*","").gsub("~",""), escape_char, implicit_braces: true)
			raise Run::RuntimeException.new "Multiple keys aren't allowed for Hotkey definitions" if key_combos.size != 1 # TODO: probably impossible?
			@key_name = key_combos[0].key_name
			@keysym = key_combos[0].keysym
			@modifiers = key_combos[0].modifiers
			@up = key_combos[0].up

			@no_grab = true if @key_str.includes? '~'
			@modifier_variants << @modifiers
			@modifier_variants << (@modifiers | ::X11::Mod2Mask.to_u32)
			if @key_str.includes? '*'
				@@available_modifier_combinations.each do |other|
					if ! @modifier_variants.includes? (modifiers | other)
						@modifier_variants << (@modifiers | other)
					end
				end
			end
		end
		def trigger
			@runner.not_nil!.add_thread @cmd.not_nil!, @priority
		end
	end
end