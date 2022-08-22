class Cmd::Misc::Pause < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(thread, args)
		mode = case args[0]?.try &.downcase
		when "on" then true
		when "off" then false
		else nil end
		thread.runner.pause_thread mode
	end
end