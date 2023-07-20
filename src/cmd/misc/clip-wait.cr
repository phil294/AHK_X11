# ClipWait [, SecondsToWait]
class Cmd::Misc::ClipWait < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def self.sets_error_level; true end
	def run(thread, args)
		timeout_sec = args[0]?.try &.to_f?
		start = Time.monotonic
		# The following works great and low on performance, but it only checks for the *possibility*
		# to retrieve text, even when it's empty:
		# thread.runner.display.gtk.clipboard &.wait_is_text_available
		# So we need to resort to looping which you could also easily do with ahk code itself.
		back_off_wait = 5.milliseconds
		while (txt = thread.runner.display.gtk.clipboard &.wait_for_text || "").empty?
			if timeout_sec
				return "1" if Time.monotonic - start > timeout_sec.seconds
			end
			sleep back_off_wait
			back_off_wait = ::Math.min(back_off_wait * 1.2, 0.5.seconds)
		end
		"0"
	end
end