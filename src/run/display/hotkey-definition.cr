require "../key-combination"

module Run
	class HotkeyDefinition < KeyCombination
		getter key_str : String # TODO: rename to something better
		getter label : String
		property priority : Int32
		getter no_grab = false
		getter wildcard = false
		getter max_threads : UInt8
		# TODO: why not move key_str to key_combo parsing into this class? it's also used twice from outside places / used to be like that previously?
		def initialize(@key_str, *, @label, key_combo, @priority, @max_threads)
			super(key_combo.key_name, text: nil, modifiers: key_combo.modifiers, up: key_combo.up, down: key_combo.down, repeat: 1)
			init
		end
		def initialize(@key_str, *, key_combo, @priority, @max_threads)
			super(key_combo.key_name, text: nil, modifiers: key_combo.modifiers, up: key_combo.up, down: key_combo.down, repeat: 1)
			@label = @key_str
			init
		end
		def init
			@no_grab = @key_str.includes? '~'
			@wildcard = @key_str.includes? '*'
		end

		# todo why not overwrite Modifiers.== ?
		def modifiers_match(mod)
			{% for key in KeyCombination::Modifiers.instance_vars %}
				return false if
					@modifiers.{{key}} ? ! mod.{{key}} :
					! @wildcard && mod.{{key}}
			{% end %}
			true
		end
	end
end