class Cmd::Misc::AHK_X11_track_performance_stop < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread, args)
		thread.settings.ahk_x11_track_performance = false
		pp (thread.performance_by_cmd.to_a.sort do |a, b|
			(b[1].total - a[1].total).nanoseconds
		end)
		thread.performance_by_cmd = {} of ::String => ::Run::CmdPerformance
	end
end