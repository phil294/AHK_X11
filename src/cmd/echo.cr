require "./cmd"

# INCOMPAT: exists
class EchoCmd < Cmd
	def self.name; "echo"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(runner)
		puts runner.str(@args[0])
	end
end