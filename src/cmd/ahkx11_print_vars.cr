require "./cmd"

# INCOMPAT: exists
class AHKX11_print_vars_Cmd < Cmd
	def self.name; "ahkx11_print_vars"; end
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(runner)
		runner.print_vars
	end
end