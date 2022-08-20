class Cmd::File::FileCreateDir < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def self.sets_error_level; true end
	def run(thread, args)
		begin
			::Dir.mkdir_p args[0]
			"0"
		rescue
			"1"
		end
	end
end