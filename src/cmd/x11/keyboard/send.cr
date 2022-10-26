class Cmd::X11::Keyboard::Send < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.x11.pause do # to prevent hotkey from triggering other hotkey or itself
			thread.runner.x_do.clear_active_modifiers thread.runner.x_do.active_modifiers
			thread.parse_key_combinations_to_charcodemap(args[0]) do |key_map, pressed|
				thread.runner.x_do.keys_raw key_map, pressed: pressed, delay: 0
			end
		end
	end
end