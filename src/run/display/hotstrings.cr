require "x11"

module Run
	alias HotstringAbbrevKeysyms = StaticArray(Char, 30)

	# Handles key presses with an internal buffer and calls threads
	# on hotstring match.
	class Hotstrings
		@hotstrings = [] of Hotstring
		@runner : Runner

		def initialize(@runner, @end_chars)
		end

		def run
			@runner.display.register_key_listener do |key_event, keysym, char|
				handle_event(key_event, keysym, char)
			end
		end

		def add(hotstring)
			@hotstrings << hotstring
		end

		# Not using `String` here because it's more convenient (and also faster) to just
		# move a char* pointer around
		@key_buff = HotstringAbbrevKeysyms.new('0')
		@key_buff_i = 0_u8

		@end_chars = [] of Char
		@candidate : Hotstring? = nil
		@modifier_keysyms : StaticArray(Int32, 13) = StaticArray[::X11::XK_Shift_L, ::X11::XK_Shift_R, ::X11::XK_Control_L, ::X11::XK_Control_R, ::X11::XK_Caps_Lock, ::X11::XK_Shift_Lock, ::X11::XK_Meta_L, ::X11::XK_Meta_R, ::X11::XK_Alt_L, ::X11::XK_Alt_R, ::X11::XK_Super_L, ::X11::XK_Super_R, ::X11::XK_Num_Lock]

		def handle_event(key_event, keysym, char)
			up = key_event.type == ::X11::KeyRelease || key_event.type == ::X11::ButtonRelease
			return if ! up
			prev_candidate = @candidate
			@candidate = nil
			if ! char
				if @modifier_keysyms.includes? keysym
					# left/right buttons etc. should cancel current buffer but modifiers not: keep
					@candidate = prev_candidate
				else
					@key_buff_i = 0_u8
				end
			else
				normal_keypress = (::X11::ControlMask | ::X11::Mod1Mask | ::X11::Mod4Mask | ::X11::Mod5Mask) & key_event.state == 0
				if normal_keypress
					if char == '\b' # ::X11::XK_BackSpace
						@key_buff_i -= 1 if @key_buff_i > 0
					elsif @end_chars.includes?(char)
						@key_buff_i = 0_u8
						if ! prev_candidate.nil?
							@runner.set_global_built_in_static_var("A_EndChar", char.to_s)
							prev_candidate.trigger(@runner)
						end
					else
						@key_buff_i = 0_u8 if @key_buff_i > 29
						@key_buff[@key_buff_i] = char
						@key_buff_i += 1
						match = @hotstrings.find { |hs| hs.keysyms_equal?(@key_buff, @key_buff_i) }
						if match
							if match.immediate
								@key_buff_i = 0_u8
								@runner.set_global_built_in_static_var("A_EndChar", "")
								match.trigger(@runner)
							else
								@candidate = match
							end
						end
					end
				else
					@key_buff_i = 0_u8
				end
			end
		end
	end
end
