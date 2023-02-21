# Goto, Label
class Cmd::ControlFlow::Goto < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.goto(args[0].downcase)
	end
end