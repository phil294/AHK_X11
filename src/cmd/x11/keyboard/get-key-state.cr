# GetKeyState, OutputVar, KeyName [, Mode]
class Cmd::X11::Keyboard::GetKeyState < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def run(thread, args)
		out_var, key_name = args
		mode = ""
		combo = thread.parse_key_combinations(key_name, implicit_braces: true).try &.[0]?
		keysym = nil
		if combo
			keysym = thread.runner.display.adapter.key_combination_to_keysym(combo)
			if keysym
				if thread.runner.display.pressed_keys.includes?(keysym)
					mode = "D"
				else
					mode = "U"
				end
			end
		end
		thread.runner.set_user_var(out_var, mode)
	end
end