class Cmd::File::SetWorkingDir < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def self.sets_error_level; true end
	def run(thread, args)
		begin
			Dir.cd args[0]
		rescue e : ::File::Error
			return "1"
		end
		thread.runner.set_global_built_in_static_var("A_WorkingDir", Dir.current)
		"0"
	end
end