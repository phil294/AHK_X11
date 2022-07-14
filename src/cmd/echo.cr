require "./base"

module Cmd
	# INCOMPAT: exists
	class Echo < Base
		def self.min_args; 1 end
		def self.max_args; 1 end
		def run(thread)
			puts thread.runner.str(@args[0])
		end
	end
end