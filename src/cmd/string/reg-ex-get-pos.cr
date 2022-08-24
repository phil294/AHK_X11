class Cmd::String::RegExGetPos < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 3 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var, in_var, search_text = args
		search_text = Regex.new(search_text, Regex::Options::IGNORE_CASE)
		text = thread.runner.get_user_var(in_var)
		i = text.index(search_text) || -1
		thread.runner.set_user_var(out_var, i.to_s)
		i == -1 ? "1" : "0"
	end
end