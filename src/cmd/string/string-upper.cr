# StringUpper, OutputVar, InputVar [, T]
class Cmd::String::StringUpper < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def run(thread, args)
		out_var, in_var = args
		title_case = args[2]? && args[2].downcase == "t"
		text = thread.get_var(in_var)
		if title_case
			text = text.titleize
		else
			text = text.upcase
		end
		thread.runner.set_user_var(out_var, text)
	end
end