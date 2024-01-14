# Send, Keys
class Cmd::X11::Keyboard::Send < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		# FIXME reactivate
		# thread.runner.display.pause do # to prevent hotkey from triggering other hotkey or itself
			thread.runner.display.adapter.send(thread, thread.parse_key_combinations(args[0]))
		# end
	end
end