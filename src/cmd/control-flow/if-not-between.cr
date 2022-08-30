class Cmd::ControlFlow::IfNotBetween < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def self.conditional; true end
	def run(thread, args)
		a = thread.get_var(args[0]) || ""
		split = args[1].split(" and ").map &.strip
		b = split[0]
		c = split[1]? || ""
		a_f = a.to_f?
		b_f = b.to_f?
		c_f = c.to_f?
		if a_f && b_f && c_f
			a_f < b_f || a_f > c_f
		else
			a < b || a > c
		end
	end
end