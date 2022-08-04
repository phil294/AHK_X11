require "../base"

class Cmd::X11::Send < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.x11.pause # to prevent hotkey from triggering other hotkey or itself
		thread.parse_keys(args[0]) do |key_map, pressed|
			thread.runner.x_do.keys_raw key_map, pressed: pressed, delay: 0
		end
		thread.runner.x11.resume
	end
end