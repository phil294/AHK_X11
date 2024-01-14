# StringSplit, OutputArray, InputVar [, Delimiters, OmitChars, FutureUse]
class Cmd::String::StringSplit < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 5 end
	def run(thread, args)
		out_var = args[0]
		in_var = args[1]
		str = thread.get_var(in_var)
		omit_chars = args[3]?
		if args[2]? && ! args[2].empty?
			regex_delims = args[2].split("")
				.map { |d| Regex.escape(d) }
				.join
			split_by = Regex.new("[" + regex_delims + "]")
		else
			split_by = ""
		end
		arr = str.split(split_by)
		thread.runner.set_user_var("#{out_var}0", arr.size.to_s)
		arr.each_with_index do |val, i|
			val = val.strip(omit_chars) if omit_chars
			thread.runner.set_user_var("#{out_var}#{i + 1}", val)
		end
	end
end