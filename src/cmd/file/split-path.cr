# SplitPath, InputVar [, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive]
class Cmd::File::SplitPath < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def run(thread, args)
		path = Path.new thread.get_var(args[0])
		thread.runner.set_user_var(args[1], path.basename) if args[1]?
		thread.runner.set_user_var(args[2], path.dirname) if args[2]?
		thread.runner.set_user_var(args[3], path.extension[1..]?||"") if args[3]?
		thread.runner.set_user_var(args[4], path.stem) if args[4]?
	end
end