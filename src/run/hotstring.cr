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
		@case_sensitive = false
		@conform_case = true # TODO not implemented
		def initialize(@label, @abbrev, *, options, escape_char)
			Util::AhkString.parse_letter_options(options, escape_char) do |char, n|
				case char
				when '*' then @immediate = true
				when 'b' then @automatic_backspacing = n != 0
				when 'c'
					@case_sensitive = n == nil
					@conform_case = n != 1
				end
			end
		end
		def keysyms_equal?(other_keysyms : HotstringAbbrevKeysyms, other_size : UInt8)
			return false if other_size != @abbrev.size
			puts other_keysyms.join[...other_size], @abbrev
			if @case_sensitive
				other_keysyms.join[...other_size] == @abbrev
			else
				other_keysyms.join[...other_size].downcase == @abbrev.downcase
			end
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