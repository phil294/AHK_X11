module Run
	# Something to listen to key(/mouse) events + call `key_handler` when received, and hotkey grabbing
	# TODO change name / input interface
	# todo maybe remove this file
	module DisplayAdapter
		abstract def run(*, key_handler : Proc(KeyCombination, UInt64, Nil))
		abstract def grab_hotkey(hotkey : Hotkey)
		abstract def ungrab_hotkey(hotkey : Hotkey)
		abstract def grab_keyboard
		abstract def ungrab_keyboard
		abstract def key_combination_to_keysym(key_combo : KeyCombination) : UInt64?
		abstract def send(key_combos : Array(KeyCombination))
		abstract def send_raw(text : String)
		abstract def screen_width : UInt32
		abstract def screen_height : UInt32
		abstract def mouse_move(thread : Thread, x : Int32?, y : Int32?, relative : Bool)
		abstract def mouse_pos : Tuple(UInt32, UInt32)
		abstract def mouse_down(mouse_keysym : Int32)
		abstract def mouse_up(mouse_keysym : Int32)
	end
end