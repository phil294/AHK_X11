class Cmd::ControlFlow::IfNotExist < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def self.multi_command; true end
	def self.conditional; true end
	def run(thread, args)
		Dir.glob(args[0]).empty?
	end
end