require "./cmd"

class SetEnvCmd < Cmd
	def self.name; "setenv"; end
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(runner)
		runner.user_vars[@args[0]] = runner.str(@args[1]? || "")
	end
end