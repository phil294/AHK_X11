require "../../../util/exponential-back-off.cr"
require "./win-util"
# WinWait, WinTitle, WinText, Seconds [, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinWait < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 5 end
	def self.sets_error_level; true end
	def run(thread, args)
		seconds = args[2].to_f? || 0.5
		seconds = 0.5 if seconds == 0
		match_conditions = args
		match_conditions.delete_at(2)
		match = ::Util::ExponentialBackOff.back_off(initial_wait: 20.milliseconds, factor: 1.15, max_wait: 0.8.seconds, timeout: seconds.seconds) do
			Util.match(thread, match_conditions, empty_is_last_found: false, a_is_active: false) do |win|
				thread.settings.last_found_window = win
			end
		end
		match ? "0" : "1"
	end
end