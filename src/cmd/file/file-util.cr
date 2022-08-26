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
		pattern = Path[pattern]
		if recurse == 1
			pattern = Path[pattern.dirname, "**", pattern.basename]
		end
		pp! pattern
		files = [] of ::String
		Dir.glob(pattern).each do |match|
			if operate_on_folders == 0
				next if ::File.directory?(match)
			elsif operate_on_folders == 2
				next if ::File.file?(match)
			end
			yield match
		end
		files.size
	end
end