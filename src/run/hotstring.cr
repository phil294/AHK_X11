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
		@delay = 0_f64
		getter omit_ending_character = false
		@priority = 0
		getter auto_send_raw = false
		def initialize(@label, @abbrev, *, options, escape_char)
			Util::AhkString.parse_letter_options(options, escape_char) do |char, n|
				case char
				when '*' then @immediate = n != 0
				when 'b' then @automatic_backspacing = n != 0
				when 'c'
					@case_sensitive = n == nil
					@conform_case = n != 1
				when 'k' then @delay = n || 0
				when 'o' then @omit_ending_character = n != 0
				when 'p' then @priority = n ? n.to_i : 0
				when 'r' then @auto_send_raw = n != 0
				end
			end
		end
		def keysyms_equal?(other_keysyms : HotstringAbbrevKeysyms, other_size : UInt8)
			return false if other_size != @abbrev.size
			if @case_sensitive
				other_keysyms.join[...other_size] == @abbrev
			else
				other_keysyms.join[...other_size].downcase == @abbrev.downcase
			end
		end
		def trigger
			runner = @runner.not_nil!

			if @automatic_backspacing
				runner.x11.pause do
					(@abbrev.size + (@immediate ? 0 : 1)).times do
						runner.x_do.keys "BackSpace", delay: 0
						sleep @delay.milliseconds if @delay != -1
					end
				end
			end
			
			runner.add_thread @cmd.not_nil!, @priority
		end
	end
end