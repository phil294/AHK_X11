# DetectHiddenWindows, On|Off
class Cmd::Misc::DetectHiddenWindows < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.settings.detect_hidden_windows = args[0].downcase == "on"
	end
end