require "./cmd"

class IfEqualCmd < Cmd
	def self.name; "ifequal"; end
	# todo is this the right syntax for these kinds of publicly accessible and inheritable class method constants?
	def self.min_args; 1 end
	def self.max_args; 2 end
	def self.multi_command; true end
	def self.control_flow; true end
	def run(thread)
		a = thread.runner.get_var(@args[0]) || ""
		b = thread.runner.str(@args[1]? || "")
		a_f = a.to_f?(strict: true)
		b_f = b.to_f?(strict: true)
		if a_f && b_f
			a_f == b_f
		else
			a == b
		end
	end
end