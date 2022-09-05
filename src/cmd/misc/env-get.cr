class Cmd::Misc::EnvGet < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def run(thread, args)
		out_var, env_name = args
		val = ENV[env_name]? || ""
		thread.runner.set_user_var(out_var, val)
	end
end