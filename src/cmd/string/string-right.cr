# StringRight, OutputVar, InputVar, Count
class Cmd::String::StringRight < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 3 end
	def run(thread, args)
		out_var, in_var, count = args
		count = count.to_i?
		text = thread.runner.get_user_var(in_var)
		return if ! count || count < 1 || text.empty?
		count = text.size if count > text.size
		text = text[text.size - count, text.size]
		return if ! text
		thread.runner.set_user_var(out_var, text)
	end
end