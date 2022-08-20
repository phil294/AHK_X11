# INCOMPAT: exists. TODO: remove again once `ListVars` exists
class Cmd::Variable::AHK_X11_print_vars < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread, args)
		thread.runner.print_user_vars
	end
end