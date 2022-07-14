require "./base"

module Cmd
	class Continue < Base
		def self.min_args; 0 end
		def self.max_args; 0 end
		def run(thread)
			true
		end
	end
end