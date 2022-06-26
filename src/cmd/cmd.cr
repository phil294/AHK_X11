abstract class Cmd
	property name = "cmd"
	abstract def initialize(args)
	abstract def run(runner)
	def conditional
		false
	end
	def self.min_args; 0 end
	# anything started at max_args and above will not be split or stripped anymore, allowing for commands with open end like SetEnv or Echo
	def self.max_args; 0 end
end

class SyntaxException < Exception end