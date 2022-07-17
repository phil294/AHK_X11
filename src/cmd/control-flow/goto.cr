require "./base"

class Cmd::Goto < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread)
		thread.goto(thread.runner.str(@args[0]))
	end
end