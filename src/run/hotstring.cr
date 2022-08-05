require "../util/ahk-string"

module Run
	alias HotstringAbbrevKeysyms = StaticArray(Char, 30)

	class Hotstring
		property runner : Run::Runner?
		getter abbrev : String
		property label : String
		property cmd : Cmd::Base?
		getter immediate = false
		@automatic_backspacing = true
		def initialize(@label, @abbrev, *, options, escape_char)
			Util::AhkString.parse_letter_options(options, escape_char) do |char, n|
				case char
				when '*' then @immediate = true
				when 'b' then @automatic_backspacing = n != 0
				end
			end
		end
		def keysyms_equal?(other_keysyms : HotstringAbbrevKeysyms, other_size : UInt8)
			other_size == @abbrev.size &&
				other_keysyms.join[...other_size] == @abbrev
		end
		def trigger
			runner = @runner.not_nil!

			if @automatic_backspacing
				runner.x11.pause
				(@abbrev.size + (@immediate ? 0 : 1)).times do
					runner.x_do.keys "BackSpace", delay: 0
				end
				runner.x11.resume
			end
			
			runner.add_thread @cmd.not_nil!, 0 # @priority
		end
	end
end