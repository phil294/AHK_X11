class Cmd::File::FileDelete < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def self.sets_error_level; true end
	def run(thread, args)
		begin
			Dir.glob(args[0]).each do |src|
				::File.delete src
			end
			"0"
		rescue
			"1"
		end
	end
end