# ClipWait [, SecondsToWait]
class Cmd::Misc::ClipWait < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def self.sets_error_level; true end
	def run(thread, args)
		timeout = args[0]?.try &.to_f?.try &.seconds
		success = ClipWait.clip_wait(thread.runner.display.gtk, timeout) do |clp|
			! clp.empty?
		end
		success ? "0" : "1"
	end

	# Waits until the clipboard passes the *&block*. Increases the sleep time inbetween operations
	# slightly exponentially, but sleeps max. 0.5 seconds.
	# Returns `true` when the *&block* returns true or `false` when *timeout* was exceeded.
	def self.clip_wait(gtk, timeout : Time::Span? = nil, &block : ::String -> Bool)
		# The following works great and low on performance, but it only checks for the *possibility*
		# to retrieve text, even when it's empty:
		# thread.runner.display.gtk.clipboard &.wait_is_text_available
		# So we need to resort to looping which you could also easily do with ahk code itself.
		back_off_wait = 5.milliseconds
		start = Time.monotonic
		loop do
			txt = gtk.clipboard &.wait_for_text || ""
			if yield(txt)
				break
			end
			if timeout
				if Time.monotonic - start > timeout
					return false
				end
			end
			sleep back_off_wait
			back_off_wait = ::Math.min(back_off_wait * 1.2, 0.5.seconds)
		end
		true
	end
end