require "./cmd"

class ReturnCmd < Cmd
	def self.name; "return"; end
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(runner)
		runner.return
	end
end