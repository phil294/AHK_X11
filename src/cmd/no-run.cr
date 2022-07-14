require "./base"

module Cmd
	module NoRun
		def self.min_args; 0 end
		def self.max_args; 0 end
		def run(thread)
			raise RuntimeException.new "Base '#{self.class.name}' cannot be run"
		end
	end
end