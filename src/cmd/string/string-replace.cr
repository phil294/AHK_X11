class Cmd::String::StringReplace < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 5 end
	def run(thread, args)
		out_var, in_var, search_text = args
		search_text = search_text.downcase
		search_text = Regex.new(Regex.escape(search_text), Regex::Options::IGNORE_CASE)
		replace_text = args[3]? || ""
		opt = (args[4]? || "").downcase
		replace_all = opt == "1" || opt == "a" || opt == "all"
		text = thread.runner.get_user_var(in_var)
		if replace_all
			text = text.gsub(search_text, replace_text)
		else
			text = text.sub(search_text, replace_text)
		end
		thread.runner.set_user_var(out_var, text)
	end
end