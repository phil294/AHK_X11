module Run
	# Something to listen to key(/mouse) events + call `key_handler` when received, and hotkey grabbing
	abstract class DisplayAdapter
		abstract def initialize
		abstract def run(*, key_handler : Proc(::X11::KeyEvent, UInt64, Char?, Nil))
		abstract def grab_hotkey(hotkey : Hotkey)
		abstract def ungrab_hotkey(hotkey : Hotkey)
	end
end