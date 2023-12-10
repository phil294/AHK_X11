# This command doesn't exist in Windows AHK
class Cmd::Misc::Eval < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.eval args[0].split('\n')
	end
end