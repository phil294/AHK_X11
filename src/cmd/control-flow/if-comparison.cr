abstract class Cmd::ControlFlow::IfComparison < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def self.multi_command; true end
	def self.conditional; true end
	def run(thread, args)
		a = thread.get_var(args[0]) || ""
		b = args[1]? || ""
		a_f = a.to_f?
		b_f = b.to_f?
		if a_f && b_f
			compare a_f, b_f
		else
			compare a, b
		end
	end
	abstract def compare(a : String | Float, b : String | Float)
end