require "./cmd"

class IfEqualCmd < Cmd
	def conditional
		true
	end # todo is this the right syntax for these kinds of publicly accessible and inheritable constants?
	def self.min_args; 1 end
	def self.max_args; 2 end
	@var : String
	@value : String
	def initialize(args)
		@var = args[0] # todo simplify these?
		@value = args[1]? || ""
	end
	def run(runner)
		a = runner.user_vars[@var]? || ""
		b = runner.str(@value)
		a_f = a.to_f?(strict: true)
		b_f = b.to_f?(strict: true)
		if a_f && b_f
			a_f == b_f
		else
			a == b
		end
	end
end