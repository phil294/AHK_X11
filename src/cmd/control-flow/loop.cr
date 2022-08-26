class Cmd::ControlFlow::Loop < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 3 end
	def self.conditional; true end
	@condition_parsed = false
	@repeat_count : Int32?
	@files = [] of ::String
	@i = 0
	# returns true (go into block) while loop condition is true, else leave this loop
	def run(thread, args)
		@i += 1
		thread.runner.set_global_built_in_static_var("A_Index", @i.to_s)
		if ! args[0]?
			return true
		else
			if ! @condition_parsed
				@repeat_count = args[0].to_i32?
				if ! @repeat_count
					Cmd::File::Util.match(args) do |match|
						@files << match
					end
				end
				@condition_parsed = true
			end
			if @repeat_count
				fin = @i > @repeat_count.not_nil!
			else
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
			end
		end
		if fin
			# reset for if visited again (e.g. another wrapping loop)
			@condition_parsed = false
			@repeat_count = 0
			@files.clear
			@i = 0
			thread.runner.set_global_built_in_static_var("A_Index", "0")
		end
		! fin
	end
end