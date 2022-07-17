require "../base"

class Cmd::Variable::SetEnv < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread)
		thread.runner.set_var(@args[0], thread.runner.str(@args[1]? || ""))
	end
end