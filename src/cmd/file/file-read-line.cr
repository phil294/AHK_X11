class Cmd::File::FileReadLine < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 3 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var, filename, line_no = args
		line_no = line_no.to_i?
		return "1" if ! line_no
		begin
			i = 1 # there's no `.each_line_with_index` ?
			match = ::File.each_line(filename) do |line|
				if i == line_no
					thread.runner.set_user_var(out_var, line)
					break true
				end
				i += 1
			end
			return match ? "0" : "1"
		rescue e
			"1"
		end
	end
end