require "random"
# Random, OutputVar [, Min, Max]
class Cmd::Math::Random < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end

	def run(thread, args)
		out_var = args[0]
		min = args[1]? || ""
		max = args[2]? || ""
		as_int = ! min.includes?('.') && ! max.includes?('.')
		if as_int
			min = min.to_i? || 0
			max = max.to_i? || Int32::MAX
			value = ::Random.new.rand(min..max)
		else
			min = min.to_f? || 0_f64
			max = max.to_f? || Int32::MAX.to_f
			value = ::Random.new.rand(min..max)
		end
		thread.runner.set_user_var(out_var, value.to_s)
	end
end