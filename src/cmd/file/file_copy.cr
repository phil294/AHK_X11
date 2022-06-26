require "../cmd"

# INCOMPAT: file mod date is not preserved (seems better this way tho), glob is case sensitive
class FileCopyCmd < Cmd
	def self.min_args; 2 end
	def self.max_args; 3 end
	@srcs : String
	@dst : String
	@flag : UInt8
	def initialize(args)
		@srcs = args[0]
		@dst = args[1]
		@flag = (args[2]?.try &.to_u8) || 0_u8
	end
	def run(runner)
		Dir.glob(runner.str(@srcs)).each do |src|
			dst = runner.str(@dst)
			dst = ! Dir.exists?(dst) ? dst :
				Path[dst, File.basename(src)]
			next if Dir.exists?(src) || Dir.exists?(dst)
			if File.exists? dst
				next if @flag == 0_u8
				File.delete dst
			end
			File.copy(src, dst)
		end
	end
end
