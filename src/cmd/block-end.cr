require "./cmd"

class BlockEndCmd < Cmd
	def self.name; "}"; end
	def self.min_args; 0 end
	def self.max_args; 0 end
	def self.multi_command; true end
	def initialize(@line_no, args); end
	def run(runner); end
end