module Run
	# The combination of ONE "normal" key and optional modifiers and up/down/repeat.
	# Does *not* yet support prefix keys like `Space & ^a`.
	# Similar to `::X11::KeyEvent`.
	class KeyCombination
		class Modifiers
			property shift = false
			property ctrl = false
			property alt = false
			property win = false
			property altgr = false
			def to_s(io)
				io << "shift:#{shift},ctrl:#{ctrl},alt:#{alt},win:#{win},altrgr:#{altgr}"
			end
		end
		getter key_name = ""
		getter text : Char?
		getter modifiers = Modifiers.new
		getter repeat = 0
		getter up = false
		getter down = false
		getter blind = false
		def initialize(@key_name, *, @text, @modifiers, @up, @down, @repeat, @blind = false) end
	end
end