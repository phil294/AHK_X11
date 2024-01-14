# BlockInput, Mode
class Cmd::X11::Keyboard::BlockInput < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		if args[0].downcase == "on"
			thread.runner.display.block_input
		else
			thread.runner.display.unblock_input
		end
	end
end