require "./cmd"

class SetEnvCmd < Cmd
	def self.name; "setenv"; end
	def self.min_args; 1 end
	def self.max_args; 2 end
	@var : String
	@value : String
	def initialize(@line_no, args)
		@var = args[0]
		@value = args[1] # todo simplify these?
	end
	def run(runner)
		runner.user_vars[@var] = runner.str(@value)
	end
end