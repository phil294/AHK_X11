require "../base"

class Cmd::SendRaw < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread)
		thread.runner.x_do.active_window.type thread.runner.str(@args[0])
	end
end