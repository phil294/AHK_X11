# StringTrimRight, OutputVar, InputVar, Count
class Cmd::String::StringTrimRight < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 3 end
	def run(thread, args)
		out_var, in_var, count = args
		text = thread.get_var(in_var)
		count = count.to_i?
		count = 0 if ! count || count < 1 || text.empty?
		end_i = text.size - count - 1
		if end_i < 0
			text = ""
		else
			text = text[0..end_i]? || ""
		end
		thread.runner.set_user_var(out_var, text)
	end
end