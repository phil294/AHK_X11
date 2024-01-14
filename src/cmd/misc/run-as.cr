# RunAs [, User, Password, Domain]
class Cmd::Misc::RunAs < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 3 end
	def run(thread, args)
		thread.runner.settings.run_as_user = args[0]?
		thread.runner.settings.run_as_password = args[1]?
	end
end