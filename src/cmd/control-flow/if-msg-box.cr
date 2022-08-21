class Cmd::ControlFlow::IfMsgBox < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def self.multi_command; true end
	def self.conditional; true end
	def run(thread, args)
		thread.settings.msgbox_response.to_s.downcase == args[0].downcase
	end
end