module Run
	# Keeps track of a list of the currently presse ddown keys
	class PressedKeys
		@runner : Runner

		def initialize(@runner)
		end

		@pressed_down_keysyms : StaticArray(UInt64, 8) = StaticArray[0_u64,0_u64,0_u64,0_u64,0_u64,0_u64,0_u64,0_u64]

		def run
			@runner.display.register_key_listener do |key_event, is_paused|
				if key_event.down
					free_slot = @pressed_down_keysyms.index(key_event.keysym) || @pressed_down_keysyms.index(0)
					@pressed_down_keysyms[free_slot] = key_event.keysym if free_slot
				end
				if key_event.up
					pressed_slot = @pressed_down_keysyms.index(key_event.keysym)
					@pressed_down_keysyms[pressed_slot] = 0_u64 if pressed_slot
				end
				# Results in 80% of the time in a segfault, but not when listed individually
				# pp! key_event, @pressed_down_keysyms
			end
		end

		def includes?(keysym)
			!! @pressed_down_keysyms.index(keysym)
		end
	end
end
