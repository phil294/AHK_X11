require "./base"

module Cmd
	class Return < Base
		def self.min_args; 0 end
		def self.max_args; 0 end
		def run(thread)
			thread.return
		end
	end
end