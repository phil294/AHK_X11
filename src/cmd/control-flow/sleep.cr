class Cmd::ControlFlow::Sleep < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		val = args[0].to_f?
		raise Run::RuntimeException.new "invalid sleep value" if ! val
		sleep val.milliseconds
	end
end