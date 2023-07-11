module Run
	# Similar to ::X11::KeyEvent, but more basic and some ahk-specific info too
	class KeyCombination
		getter key_name = ""
		getter keysym = 0_u64
		getter modifiers = 0_u32
		getter repeat = 0
		getter up = false
		getter down = false
		getter blind = false
		property keycode = 0_u8
		def initialize(@key_name, @keysym, @modifiers, @up, @down, @repeat, *, @blind = false)
		end
	end
end