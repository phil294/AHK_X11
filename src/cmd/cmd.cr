abstract class Cmd
	# abstract def self.name
	abstract def initialize(args)
	abstract def run
end

class SyntaxException < Exception end