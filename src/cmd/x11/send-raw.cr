require "../base"

class Cmd::X11::SendRaw < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.x11.pause # to prevent hotkey from triggering other hotkey or itself
		thread.runner.x_do.type args[0]
		thread.runner.x11.resume
	end
end