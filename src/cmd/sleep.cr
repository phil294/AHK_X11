require "./cmd"

class SleepCmd < Cmd
	def self.name; "sleep"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread)
		val = thread.runner.str(@args[0]).to_f?(strict: true)
		raise RuntimeException.new "invalid sleep value" if ! val
		sleep val.milliseconds
	end
end