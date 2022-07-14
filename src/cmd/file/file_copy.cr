require "../base"

module Cmd
	module File
		# INCOMPAT: file mod date is not preserved (seems better this way tho), glob is case sensitive
		class FileCopy < Base
			def self.min_args; 2 end
			def self.max_args; 3 end
			def run(thread)
				flag = thread.runner.str(@args[2]? || "0").to_u8
				dst = thread.runner.str(@args[1])
				Dir.glob(thread.runner.str(@args[0])).each do |src|
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
	end
end