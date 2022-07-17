require "../base"

# INCOMPAT: exists
class Cmd::Unix::Echo < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread)
		puts thread.runner.str(@args[0])
	end
end