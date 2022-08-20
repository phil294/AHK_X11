class Cmd::ControlFlow::ExitApp < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(thread, args)
		code = (args[0]? || "").to_i? || 0
		thread.runner.exit_app code
	end
end