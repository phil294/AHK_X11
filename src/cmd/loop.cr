require "./base"

class Cmd::Loop < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def self.control_flow; true end
	@repeat_count : Int32?
	@i = 0
	def run(thread)
		if @args[0]? && ! @repeat_count
			repeat_count = thread.runner.str(@args[0]).to_i32?(strict: true)
			raise "invalid loop count" if ! repeat_count
			@repeat_count = repeat_count
		end
		repeat_count = @repeat_count
		return true if ! repeat_count
		@i += 1
		fin = @i > repeat_count
		if fin
			# reset so it is recalculated if visited again (e.g. another wrapping loop)
			@repeat_count = nil
			@i = 0
		end
		! fin
	end
end