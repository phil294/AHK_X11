class Cmd::Misc::AHK_X11_track_performance_start < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread, args)
		thread.settings.ahk_x11_track_performance = true
	end
end