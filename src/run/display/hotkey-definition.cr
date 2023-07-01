require "../key-combination"

module Run
	class HotkeyDefinition < KeyCombination
		getter key_str : String # TODO: rename to something better
		getter label : String
		property priority : Int32
		getter no_grab = false
		getter wildcard = false
		def initialize(@key_str, @label, key_combo, @priority)
			super(key_combo.key_name, text: nil, modifiers: key_combo.modifiers, up: key_combo.up, down: key_combo.down, repeat: 1)
			init
		end
		def initialize(@key_str, key_combo, @priority)
			super(key_combo.key_name, text: nil, modifiers: key_combo.modifiers, up: key_combo.up, down: key_combo.down, repeat: 1)
			@label = @key_str
			init
		end
		def init
			@no_grab = true if @key_str.includes? '~'
			@wildcard = true if @key_str.includes? '*'
		end

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