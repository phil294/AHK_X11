require "../../util/ahk-string"
require "./hotstrings"

module Run
	class Hotstring
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
		def trigger(runner, trigger_char_key_event)
			runner.display.pause do
				if @automatic_backspacing
					(@abbrev.size + (@immediate ? 0 : 1)).times do
						runner.display.x_do.keys "BackSpace", delay: 0
						sleep @delay.milliseconds if @delay != -1
					end
				end
				# Same xdotool workaround as in send.cr.
				# Trigger char is either end key or the last key of an immediate hotstring.
				# TODO: tests for both cases:
				# end key space: `::btw::by the way` without this the first space is missing (test didn;t fail though??)
				# no end key: `:*:btw::wy the way` the `w` wasn't typed
				end_char_key_up = XDo::LibXDo::Charcodemap.new
				end_char_key_up.code = trigger_char_key_event.keycode
				runner.display.x_do.keys_raw [end_char_key_up], pressed: false, delay: 0
			end

			runner.add_thread @cmd.not_nil!, @label, @priority
		end
	end
end