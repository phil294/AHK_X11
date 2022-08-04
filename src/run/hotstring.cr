require "../util/ahk-string"

module Run
	alias HotstringAbbrevKeysyms = StaticArray(Char, 30)

	class Hotstring
		property runner : Run::Runner?
		getter abbrev : String
		getter abbrev_keysyms : HotstringAbbrevKeysyms
		getter abbrev_size : UInt8
		property label : String
		property cmd : Cmd::Base?
		getter immediate = false
		def initialize(@label, @abbrev, options, escape_char)
			@abbrev_size = @abbrev.size.to_u8
			@abbrev_keysyms = HotstringAbbrevKeysyms.new do |i|
				if i >= @abbrev_size
					'0'
				else
					@abbrev[i]
				end
			end

			Util::AhkString.parse_letter_options(options, escape_char) do |char, n|
				case char
				when '*' then @immediate = true
				end
			end
		end
		def keysyms_equal?(other_keysyms : HotstringAbbrevKeysyms, other_size : UInt8)
			return false if other_size != @abbrev_size
			@abbrev_keysyms.each_with_index do |k, i|
				break if i >= @abbrev_size
				return false if k != other_keysyms[i]
			end
			true
		end
		def trigger
			runner = @runner.not_nil!

			runner.x11.pause
			(@abbrev_size + (@immediate ? 0 : 1)).times do
				runner.x_do.keys "BackSpace", delay: 0
			end
			runner.x11.resume
			
			runner.add_thread @cmd.not_nil!, 0 # @priority
		end
	end
end