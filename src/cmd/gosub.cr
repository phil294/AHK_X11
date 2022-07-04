require "./cmd"

class GosubCmd < Cmd
	def self.name; "gosub"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	@label : String
	def initialize(@line_no, args)
		@label = args[0]
	end
	def run(runner)
		runner.gosub @label
	end
end