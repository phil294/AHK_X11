require "./cmd"

class ContinueCmd < Cmd
	def self.name; "continue"; end
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread)
		true
	end
end