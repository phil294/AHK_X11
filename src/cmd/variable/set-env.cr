class Cmd::Variable::SetEnv < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread, args)
		thread.runner.set_user_var(args[0], args[1]? || "")
	end
end