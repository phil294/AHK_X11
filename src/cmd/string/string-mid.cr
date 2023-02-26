# StringMid, OutputVar, InputVar, StartChar, Count [, L]
class Cmd::String::StringMid < Cmd::Base
	def self.min_args; 4 end
	def self.max_args; 5 end
	def run(thread, args)
		out_var, in_var, start, count = args
		start = start.to_i? || 1
		start = 1 if start < 1
		start -= 1
		count = count.to_i?
		if ! count || count < 1
			text = ""
		else
			text = thread.runner.get_user_var(in_var)
			text = text[start, count]
		end
		thread.runner.set_user_var(out_var, text)
	end
end