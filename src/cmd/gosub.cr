require "./base"

module Cmd
	class Gosub < Base
		def self.min_args; 1 end
		def self.max_args; 1 end
		def run(thread)
			thread.gosub(thread.runner.str(@args[0]))
		end
	end
end