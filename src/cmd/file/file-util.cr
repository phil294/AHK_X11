class Cmd::File::Util
	# Finds files based on pattern and yields them each.
	# param `match_conditions` is those three `FilePattern[, IncludeFolders?, Recurse?]`
	# from the docs that are used in various file-related commands,
	# and can consequently also be an empty array.
	# Returns the amount of files matched.
	def self.match(match_conditions)
		pattern = match_conditions[0]?
		operate_on_folders = (match_conditions[1]?.try &.to_i?) || 0
		recurse = (match_conditions[2]?.try &.to_i?) || 0
		return 0 if ! pattern
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
		files.each do |file|
			yield file
		end
		files.size
	end
end