require "./cmd"

class BreakCmd < Cmd
	def self.name; "break"; end
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(runner)
		true
	end
end