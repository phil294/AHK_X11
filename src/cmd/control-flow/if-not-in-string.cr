class Cmd::ControlFlow::IfNotInString < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def self.multi_command; true end
	def self.conditional; true end
	def run(thread, args)
		var_name, search_string = args
		! thread.get_var(var_name).downcase.includes?(search_string.downcase)
	end
end