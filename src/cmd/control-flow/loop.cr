# Loop [, Count]
# Loop, FilePattern [, IncludeFolders?, Recurse?]
# Loop, Parse, InputVar [, Delimiters, OmitChars, FutureUse]
# Loop, Read, InputFile [, OutputFile, FutureUse]
class Cmd::ControlFlow::Loop < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def self.conditional; true end
	enum LoopType
		Endless
		Count
		Files
		Read
		Parse
	end
	@type : LoopType? = nil
	@count : Int32?
	@files = [] of ::String
	@read_input_file : ::File? = nil
	getter read_output_file : ::File? = nil
	getter index = 0
	@parse_iter : Iterator(::String)?
	# Set up counters etc., register loop as innermost, open resources etc.
	private def init(thread, args)
		if ! args[0]?
			@type = LoopType::Endless
		else
			@count = args[0].to_i32?
			if @count
				@type = LoopType::Count
			else
				case args[0].downcase
				when "read"
					@type = LoopType::Read
					raise Run::RuntimeException.new "Loop, Read: Input file missing" if ! args[1]? || args[1].empty?
					@read_input_file = ::File.new(args[1])
					@read_output_file = ::File.new(args[2], "a") if args[2]?
				when "parse"
					@type = LoopType::Parse
					raise Run::RuntimeException.new "Loop, Parse: Input var missing" if ! args[1]? || args[1].empty?
					# There is only ::String::each_line but not for custom delimiters, so crafting RegExes seems to be
					# the most straightforward way here, although sequential reading instead of .split would be better
					txt = thread.get_var(args[1])
					delimiters = Regex.new((args[2]? || "").split("").map { |c| Regex.escape(c) }.join('|'))
					parse_arr = txt.split(delimiters)
					omit_chars = (args[3]? || "").split("").map { |c| Regex.escape(c) }.join('|')
					parse_omit_chars_regex = Regex.new("^(?:#{omit_chars})*([\\w\\W]*?)(?:#{omit_chars})*$")
					@parse_iter = parse_arr.each.map &.gsub(parse_omit_chars_regex, "\\1")
				else
					@type = LoopType::Files
					Cmd::File::Util.match(args) do |match|
						@files << match
					end
				end
			end
		end
		thread.loop_stack << self
	end
	# returns true (go into block) while loop condition is true, else leave this loop
	def run(thread, args)
		if ! @type
			init(thread, args)
		end
		@index += 1
		case @type
		when LoopType::Endless
			fin = false
		when LoopType::Count
			fin = @index > @count.not_nil!
		when LoopType::Files
			file = current_file
			fin = ! current_file
			if file
				path = Path.new(file.path)
				stat = uninitialized LibC::Stat
				Crystal::System::File.stat(file.path.check_no_null_byte, pointerof(stat))
				access_time = ::Time.new(stat.st_atim, ::Time::Location::UTC)
				# st_ctim is not creation time. Creation time is not available on Crystal, see
				# https://github.com/crystal-lang/crystal/issues/12416
				# creation_time = ::Time.new(stat.st_ctim, ::Time::Location::UTC)
				thread.runner.set_global_built_in_static_var("A_LoopFileName", path.basename)
				thread.runner.set_global_built_in_static_var("A_LoopFileFullPath", file.path)
				thread.runner.set_global_built_in_static_var("A_LoopFileShortName", path.basename)
				thread.runner.set_global_built_in_static_var("A_LoopFileDir", path.dirname)
				thread.runner.set_global_built_in_static_var("A_LoopFileTimeModified", file.info.modification_time.to_YYYYMMDDHH24MISS)
				# thread.runner.set_global_built_in_static_var("A_LoopFileTimeCreated", "") # TODO: s. above
				thread.runner.set_global_built_in_static_var("A_LoopFileTimeAccessed", access_time.to_YYYYMMDDHH24MISS)
				# thread.runner.set_global_built_in_static_var("A_LoopFileAttrib", path.basename)
				thread.runner.set_global_built_in_static_var("A_LoopFileSize", file.info.size.to_s)
				thread.runner.set_global_built_in_static_var("A_LoopFileSizeKB", (file.info.size / 1024).to_i.to_s)
				thread.runner.set_global_built_in_static_var("A_LoopFileSizeMB", (file.info.size / 1024 / 1024).to_i.to_s)
			end
		when LoopType::Read
			line = @read_input_file.not_nil!.gets
			if line.nil?
				fin = true
			else
				fin = false
				thread.runner.set_user_var("A_LoopReadLine", line)
			end
		when LoopType::Parse
			field = @parse_iter.not_nil!.next
			if field.is_a?(Iterator::Stop)
				fin = true
			else
				fin = false
				thread.runner.set_user_var("A_LoopField", field)
			end
		else
			fin = false
		end
		finish(thread) if fin
		! fin
	end
	# reset for if visited again (e.g. another wrapping loop), close open resources etc
	def finish(thread)
		@type = nil
		@count = 0
		@files.clear
		@index = 0
		@read_input_file.not_nil!.close if @read_input_file
		@read_output_file.not_nil!.close if @read_output_file
		@parse_iter = nil
		thread.loop_stack.pop
	end
	def current_file
		match = @files[@index - 1]?
		return nil if ! match
		::File.new(match)
	end
end