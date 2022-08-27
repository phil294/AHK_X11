require "./file-util"
class Cmd::File::FileSetAttrib < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 5 end
	def self.sets_error_level; true end
	def run(thread, args)
		time = args[0]?
		if time
			time = ::Time.parse_YYYYMMDDHH24MISS?(time)
		end
		if ! time
			time = ::Time.now
		end
		which_time = (args[2]?.try &.downcase) || "m"
		args.delete_at(0) # TODO:
		args.delete_at(1) # TODO:
		Util.match(args) do |match|
			if which_time == "m"
				::File.modification_time = time
			end
		end
		"0" # TODO: file count
	end
end