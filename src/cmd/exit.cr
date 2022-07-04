require "./cmd"

class ExitCmd < Cmd
	def self.name; "exit"; end
	def self.min_args; 0 end
	def self.max_args; 1 end
	@exit_code : Int32?
	def initialize(@line_no, args)
		@exit_code = args[0]?.try &.to_i
	end
	def run(runner)
		runner.exit @exit_code
	end
end