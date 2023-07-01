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
			@runner.display.register_key_listener do |key_event, keysym, is_paused|
				handle_event(key_event, keysym, is_paused)
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

		def handle_event(key_event, keysym, is_paused)
			return if is_paused
			return if ! key_event.down
			# TODO: why not compare keysyms instead like hotkeys.cr?
			char = key_event.text
			prev_candidate = @candidate
			@candidate = nil
			if ! char
				# FIXME:
				# @modifier_keysyms : StaticArray(Int32, 13) = StaticArray[::X11::XK_Shift_L, ::X11::XK_Shift_R, ::X11::XK_Control_L, ::X11::XK_Control_R, ::X11::XK_Caps_Lock, ::X11::XK_Shift_Lock, ::X11::XK_Meta_L, ::X11::XK_Meta_R, ::X11::XK_Alt_L, ::X11::XK_Alt_R, ::X11::XK_Super_L, ::X11::XK_Super_R, ::X11::XK_Num_Lock]
				# if @modifier_keysyms.includes? key_event.keysym
				# 	# left/right buttons etc. should cancel current buffer but modifiers not: keep
				# 	@candidate = prev_candidate
				# else
					@key_buff_i = 0_u8
				# end
			else
				# FIXME
				# normal_keypress = (::X11::ControlMask | ::X11::Mod1Mask | ::X11::Mod4Mask | ::X11::Mod5Mask) & key_event.modifiers == 0
				normal_keypress = true
				if normal_keypress
					if keysym == ::X11::XK_BackSpace
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
