class Cmd::File::FileSetAttrib < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 4 end
	def self.sets_error_level; true end
	def run(thread, args)
		attr = args[0]
		pattern = args[1]?
		operate_on_folders = (args[2]?.try &.to_i?) || 0
		recurse = (args[3]?.try &.to_i?) || 0

		return "0" if ! pattern
		files = [] of ::String
		Dir.glob(pattern).each do |match|
			if ::File.directory?(match)
				next if operate_on_folders == 0
				if recurse == 1
					files.concat(Dir.glob(match + "/**/*"))
				end
			elsif ::File.file?(match)
				next if operate_on_folders == 2
			end
			files << match
		end
		files.each do |match|
			on = off = toggle = false
			perm = ::File.directory?(match) ? 0o755 : 0o644
			attr.each_char do |c|
				case c.downcase
				when '+' then on = true
				when '-' then off = true
				when '^' then toggle = true
				when 'x'
					if on
						perm = 0o755
					elsif toggle
						perm = 0o755 if ! ::File.executable?(match)
					end
					on = off = toggle = false
				when 'n'
					on = off = toggle = false
				end
			end
			::File.chmod(match, perm)
		end
		"0"
	end
end