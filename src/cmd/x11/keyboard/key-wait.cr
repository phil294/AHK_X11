class Cmd::X11::Keyboard::KeyWait < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread, args)
		key_name = args[0]
		down = (args[1]?.try &.downcase) == "d"
		keysym = thread.parse_key_combinations(key_name, implicit_braces: true)[0]?.try &.keysym
		raise Run::RuntimeException.new "Key #{key_name} not found" if ! keysym
		loop do
			is_pressed = thread.runner.x11.keysym_pressed_down?(keysym)
			break if down ? is_pressed : !is_pressed
			sleep 33.milliseconds
		end
	end
end