require "./cmd"

class LoopCmd < Cmd
	def self.name; "loop"; end
	def self.min_args; 0 end
	def self.max_args; 1 end
	def self.control_flow; true end
	@repeat_count : Int32?
	@i = 0
	def initialize(@line_no, args)
		if args[0]?
			repeat_count = args[0].to_i32?(strict: true)
			raise "Expected integer number" if ! repeat_count
			@repeat_count = repeat_count
		end
	end
	def run(runner)
		repeat_count = @repeat_count
		return true if ! repeat_count
		@i += 1
		fin = @i > repeat_count
		@i = 0 if fin
		! fin
	end
end