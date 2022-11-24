require "time"

class Cmd::X11::Keyboard::KeyWait < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def self.sets_error_level; true end
	def run(thread, args)
		key_name = args[0]
		down = false
		timeout = nil
		thread.parse_letter_options(args[1]? || "") do |c, n|
			case c
			when 'd' then down = true
			when 't' then timeout = n
			end
		end
		keysym = thread.parse_key_combinations(key_name, implicit_braces: true)[0]?.try &.keysym
		raise Run::RuntimeException.new "Key #{key_name} not found" if ! keysym
		start = Time.monotonic
		loop do
			is_pressed = thread.runner.display.keysym_pressed_down?(keysym)
			break if down ? is_pressed : !is_pressed
			sleep 20.milliseconds
			now = Time.monotonic
			if timeout
				if now - start >= timeout.not_nil!.seconds
					return "1"
				end
			end
		end
		"0"
	end
end