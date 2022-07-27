require "../base"

class Cmd::ControlFlow::Break < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread, args)
		thread.runner.set_built_in_static_var("A_Index", "0")
	end
end