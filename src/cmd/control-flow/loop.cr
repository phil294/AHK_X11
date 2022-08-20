class Cmd::ControlFlow::Loop < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def self.conditional; true end
	@repeat_count : Int32?
	@i = 0
	# returns true (go into block) while loop condition is true, else leave this loop
	def run(thread, args)
		if args[0]? && ! @repeat_count
			repeat_count = args[0].to_i32?(strict: true)
			raise Run::RuntimeException.new "Invalid loop count" if ! repeat_count
			@repeat_count = repeat_count
		end
		repeat_count = @repeat_count
		@i += 1
		thread.runner.set_global_built_in_static_var("A_Index", @i.to_s)
		return true if ! repeat_count
		fin = @i > repeat_count
		if fin
			# reset so it is recalculated if visited again (e.g. another wrapping loop)
			@repeat_count = nil
			@i = 0
			thread.runner.set_global_built_in_static_var("A_Index", "0")
		end
		! fin
	end
end