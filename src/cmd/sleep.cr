require "./cmd"

class SleepCmd < Cmd
	def self.name; "sleep"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	@val : Float64
	def initialize(@line_no, args)
		@val = args[0].to_f(strict: true)
	end
	def run(runner)
		sleep @val
	end
end