require "./cmd"

class ExitCmd < Cmd
	def self.name; "exit"; end
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(runner)
		code = runner.str(@args[0]? || "").to_i? || 0
		runner.exit code
	end
end