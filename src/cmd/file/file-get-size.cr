# FileGetSize, OutputVar [, Filename, Units]
class Cmd::File::FileGetSize < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var = args[0]
		filename = args[1]?
		if ! filename || filename.empty?
			file = (thread.loop_stack.reverse.find &.current_file).try &.current_file
			return "1" if ! file
		else
			return "1" if ! ::File.exists?(filename)
			file = ::File.new(filename)
		end
		size = case args[2]?.try &.downcase
		when "k" then file.info.size / 1024
		when "m" then file.info.size / 1024 / 1024
		else file.info.size end
		thread.runner.set_user_var(out_var, size.to_i.to_s)
	end
end