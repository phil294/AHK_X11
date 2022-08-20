class Cmd::File::FileAppend < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def self.sets_error_level; true end
	def run(thread, args)
		text, filename = args
		begin
			::File.write(filename, text, mode: "a")
			"0"
		rescue
			"1"
		end
	end
end