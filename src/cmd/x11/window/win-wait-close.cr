require "../../../util/exponential-back-off.cr"
require "./win-util"
# WinWaitClose, WinTitle, WinText, Seconds [, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinWaitClose < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 5 end
	def self.sets_error_level; true end
	def run(thread, args)
		seconds = args[2].to_f?
		seconds = 0.5 if seconds == 0
		match_conditions = args
		match_conditions.delete_at(2)
		is_gone = false
		::Util::ExponentialBackOff.back_off(initial_interval: 20.milliseconds, factor: 1.15, max_interval: 0.8.seconds, timeout: seconds ? seconds.seconds : nil) do
			Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: false) do |win|
				# Since LastFoundWindow is allowed, we might get that back even though it doesn't exist anymore,
				# so we verify if the window is dead:
				is_gone = ! win.name
			end
			is_gone
		end
		is_gone ? "0" : "1"
	end
end