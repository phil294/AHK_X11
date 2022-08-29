require "./file-util"
class Cmd::File::FileSetTime < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 5 end
	def self.sets_error_level; true end
	def run(thread, args)
		time = args[0]?
		if time
			time = ::Time.parse_YYYYMMDDHH24MISS?(time)
		end
		if ! time
			time = ::Time.local
		end
		which_time = (args[2]?.try &.downcase) || "m"
		args.delete_at(0) if args[0]?
		args.delete_at(1) if args[1]?
		Util.match(args) do |match|
			if which_time == "m"
				::File.touch(match, time)
			end
		end
		"0"
	end
end