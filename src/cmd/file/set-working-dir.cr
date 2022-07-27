require "../base"

class Cmd::File::SetWorkingDir < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		begin
			Dir.cd args[0]
		rescue e : ::File::Error
			thread.set_thread_built_in_static_var("ErrorLevel", "1")
			return
		end
		thread.runner.set_global_built_in_static_var("A_WorkingDir", Dir.current)
	end
end