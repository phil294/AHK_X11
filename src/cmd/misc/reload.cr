class Cmd::Misc::Reload < Cmd::Base
	def run(thread, args)
		thread.runner.reload
	end
end