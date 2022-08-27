class Cmd::ControlFlow::Loop < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def self.conditional; true end
	Enum LoopType
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
	@read_output_file : ::File? = nil
	@i = 0
	# returns true (go into block) while loop condition is true, else leave this loop
	def run(thread, args)
		if ! @type
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
						raise Run::RuntimeException "Loop, Read: Input file missing" if ! args[1]? || args[1].empty?
						@read_input_file = ::File.new(args[1])
						@read_output_file = ::File.new(args[2]) if args[2]?
						# TODO: store output file into somewhere
					# when "parse"
					else
						@type = LoopType::Files
						Cmd::File::Util.match(args) do |match|
							@files << match
						end
					end
				end
			end
		end
		case @type
		when LoopType::Endless
			fin = false
		when LoopType::Count
			fin = @i > @count.not_nil!
		when LoopType::Files
			fin = @i > @files.size
			if ! fin
				match = @files[@i - 1]
				file = ::File.new(match)
				path = Path.new(match)
				stat = uninitialized LibC::Stat
				Crystal::System::File.stat(match.check_no_null_byte, pointerof(stat))
				access_time = ::Time.new(stat.st_atim, ::Time::Location::UTC)
				# st_ctim is not creation time. Creation time is not available on Crystal, see
				# https://github.com/crystal-lang/crystal/issues/12416
				# creation_time = ::Time.new(stat.st_ctim, ::Time::Location::UTC)
				thread.runner.set_global_built_in_static_var("A_LoopFileName", path.basename)
				thread.runner.set_global_built_in_static_var("A_LoopFileFullPath", match)
				thread.runner.set_global_built_in_static_var("A_LoopFileShortName", path.basename)
				thread.runner.set_global_built_in_static_var("A_LoopFileDir", path.dirname)
				thread.runner.set_global_built_in_static_var("A_LoopFileTimeModified", file.info.modification_time.to_YYYYMMDDHH24MISS)
				# thread.runner.set_global_built_in_static_var("A_LoopFileTimeCreated", "") # TODO: s. above
				thread.runner.set_global_built_in_static_var("A_LoopFileTimeAccessed", access_time.to_YYYYMMDDHH24MISS)
				# thread.runner.set_global_built_in_static_var("A_LoopFileAttrib", path.basename)
				thread.runner.set_global_built_in_static_var("A_LoopFileSize", file.info.size.to_s)
				thread.runner.set_global_built_in_static_var("A_LoopFileSizeKB", (file.info.size / 1024).to_s)
				thread.runner.set_global_built_in_static_var("A_LoopFileSizeMB", (file.info.size / 1024 / 1024).to_s)
			end
		when LoopType::Read
			line = @read_input_file.gets
			if line == IO::Fin
				fin = true
			else
				fin = false
				thread.runner.set_user_var("A_LoopReadLine", line)
			end
		else
			fin = false
		end
		if fin
			# reset for if visited again (e.g. another wrapping loop)
			@type = nil
			@count = 0
			@files.clear
			@i = 0
			@read_input_file = nil
			@read_output_file = nil
			thread.runner.set_global_built_in_static_var("A_Index", "0")
		else
			@i += 1
			thread.runner.set_global_built_in_static_var("A_Index", @i.to_s)
		end
		! fin
	end
end