# INCOMPAT: exists
class Cmd::Unix::Echo < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		puts args[0]
	end
end