require "./cmd"

class BlockStartCmd < Cmd
	def self.name; "{"; end
	def self.min_args; 0 end
	def self.max_args; 0 end
	def initialize(@line_no, args); end
	def run(runner); end
end