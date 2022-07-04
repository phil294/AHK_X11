require "./cmd"

class GotoCmd < Cmd
	def self.name; "goto"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(runner)
		runner.goto(runner.str(@args[0]))
	end
end