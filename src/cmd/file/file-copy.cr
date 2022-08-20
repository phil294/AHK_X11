# INCOMPAT: file mod date is not preserved (seems better this way tho), glob is case sensitive
class Cmd::File::FileCopy < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def run(thread, args)
		srcs, dst, *rest = args
		flag = (rest[0]? || "0").to_u8
		Dir.glob(srcs).each do |src|
			this_dst = ! Dir.exists?(dst) ? dst :
				Path[dst, ::File.basename(src)]
			next if Dir.exists?(src) || Dir.exists?(this_dst)
			if ::File.exists? this_dst
				next if flag == 0_u8
				::File.delete this_dst
			end
			::File.copy(src, this_dst)
		end
	end
end