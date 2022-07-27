require "../base"

class Cmd::File::FileAppend < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def run(thread, args)
		text, filename = args
		::File.write(filename, text, mode: "a")
	end
end