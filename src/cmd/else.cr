require "./cmd"

class ElseCmd < Cmd
	def self.name; "else"; end
	def self.min_args; 0 end
	def self.max_args; 0 end
	def self.multi_command; true end
	def initialize(@line_no, args)
	end
	def run(runner)
		true
	end
end