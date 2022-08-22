class Cmd::Misc::Suspend < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(thread, args)
		mode = case args[0]?.try &.downcase
		when "on" then true
		when "off" then false
		else nil end
		thread.runner.suspend mode
	end
end