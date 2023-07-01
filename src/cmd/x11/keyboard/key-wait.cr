require "time"
# KeyWait, KeyName [, Options]
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
		combo = thread.parse_key_combinations(key_name, implicit_braces: true)[0]?
		keysym = thread.runner.display.adapter.key_combination_to_keysym(combo) if combo
		raise Run::RuntimeException.new "Key #{key_name} not found" if ! keysym
		is_pressed = thread.runner.display.pressed_keys.includes?(keysym)
		return "0" if down ? is_pressed : !is_pressed

		wait_channel = Channel(Nil).new

		listener = thread.runner.display.register_key_listener do
			is_pressed = thread.runner.display.pressed_keys.includes?(keysym)
			wait_channel.send(nil) if down ? is_pressed : !is_pressed
		end

		ret = select
		when wait_channel.receive
			"0"
		# Neither Time::Span::MAX nor Time::Span::ZERO works here
		when timeout(timeout ? timeout.not_nil!.seconds : 302400000.seconds)
			"1"
		end
		thread.runner.display.unregister_key_listener(listener)
		ret
	end
end