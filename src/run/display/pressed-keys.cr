module Run
	# Keeps track of a list of the currently presse ddown keys
	class PressedKeys
		@runner : Runner

		def initialize(@runner)
		end

		@pressed_down_keysyms : StaticArray(UInt64, 8) = StaticArray[0_u64,0_u64,0_u64,0_u64,0_u64,0_u64,0_u64,0_u64]

		def run
			@runner.display.register_key_listener do |key_event, keysym, char|
				up = key_event.type == ::X11::KeyRelease || key_event.type == ::X11::ButtonRelease

				if ! up
					free_slot = @pressed_down_keysyms.index(keysym) || @pressed_down_keysyms.index(0)
					@pressed_down_keysyms[free_slot] = keysym if free_slot
				else
					pressed_slot = @pressed_down_keysyms.index(keysym)
					@pressed_down_keysyms[pressed_slot] = 0_u64 if pressed_slot
				end
			end
		end

		def includes?(keysym)
			!! @pressed_down_keysyms.index(keysym)
		end
	end
end
