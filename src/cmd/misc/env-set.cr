# EnvSet, EnvVar, Value
class Cmd::Misc::EnvSet < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def run(thread, args)
		env_var, val = args
		ENV[env_var] = val
	end
end