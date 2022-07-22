require "../base"

class Cmd::SendRaw < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.x_do.active_window do |win|
			thread.runner.pause_x11 # to prevent hotkey from triggering other hotkey or itself
			win.type args[0]
			thread.runner.resume_x11
		end
	end
end