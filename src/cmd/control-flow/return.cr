class Cmd::ControlFlow::Return < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread, args)
		thread.return
	end
end