require "../cmd"

# INCOMPAT: file mod date is not preserved (seems better this way tho), glob is case sensitive
class FileCopyCmd < Cmd
	@srcs : String
	@dst : String
	@flag : UInt8
	def initialize(args)
		if args.size < 2
			raise SyntaxException.new("Too few arguments")
		end
		@srcs = args[0]
		@dst = args[1]
		@flag = (args[2]?.try &.to_u8) || 0_u8
	end
	def run
		Dir.glob(@srcs).each do |src|
			dst = ! Dir.exists?(@dst) ? @dst :
				Path[@dst, File.basename(src)]
			next if Dir.exists?(src) || Dir.exists?(dst)
			if File.exists? dst
				next if @flag == 0_u8
				File.delete dst
			end
			File.copy(src, dst)
		end
	end
end
