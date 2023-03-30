module Run
	# Similar to ::X11::KeyEvent, but more basic and some ahk-specific info too
	class KeyCombination
		getter key_name = ""
		getter text : Char?
		getter keysym = 0_u64
		getter modifiers = 0_u8
		getter repeat = 0
		getter up = false
		getter down = false
		property keycode = 0_u8
		def initialize(@key_name, @text, @keysym, @modifiers, @up, @down, @repeat) end
		def initialize(@key_name, @text, @keysym, @modifiers, @up, @down, @repeat, @keycode) end
	end
end