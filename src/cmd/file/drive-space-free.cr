# DriveSpaceFree, OutputVar, Path
class Cmd::File::DriveSpaceFree < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def run(thread, args)
		out_var, path = args
		path = path.gsub('\'', "")
		mb = `df -Pm '#{path}' | tail -1 | awk '{print $4}'`
		thread.runner.set_user_var(out_var, mb)
	end
end