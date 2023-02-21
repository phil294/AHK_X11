# FileAppend, Text, Filename
class Cmd::File::FileAppend < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def self.sets_error_level; true end
	def run(thread, args)
		text = args[0]
		filename = args[1]?
		if ! filename
			file = thread.loop_stack.last?.try &.read_output_file
			raise Run::RuntimeException.new "Missing filename parameter for FileAppend and could also not be inferred because there is no file read loop." if ! file
			file.puts(text)
			"0"
		else
			begin
				::File.write(filename, text, mode: "a")
				"0"
			rescue
				"1"
			end
		end
	end
end