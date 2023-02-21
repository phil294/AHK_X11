# StringLen, OutputVar, InputVar
class Cmd::String::StringLen < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def run(thread, args)
		out_var, in_var = args
		text = thread.runner.get_user_var(in_var)
		thread.runner.set_user_var(out_var, text.size.to_s)
	end
end