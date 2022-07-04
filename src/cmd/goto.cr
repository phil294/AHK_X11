require "./cmd"

class GotoCmd < Cmd
	def self.name; "goto"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	@label : String
	def initialize(@line_no, args)
		@label = args[0]
	end
	def run(runner)
		runner.goto @label
	end
end