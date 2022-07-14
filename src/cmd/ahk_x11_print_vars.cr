require "./cmd"

# INCOMPAT: exists
class AHK_X11_print_varsCmd < Cmd
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread)
		thread.runner.print_vars
	end
end