require "../../../util/exponential-back-off.cr"
require "./win-util"
# WinWaitActive [, WinTitle, WinText, Seconds, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinWaitActive < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 5 end
	def self.sets_error_level; true end
	def run(thread, args)
		seconds = args[2]?.try &.to_f?
		seconds = 0.5 if seconds == 0
		match_conditions = args
		match_conditions.delete_at(2) if args[2]?
		is_active = ::Util::ExponentialBackOff.back_off(initial_interval: 5.milliseconds, factor: 1.15, max_interval: 0.8.seconds, timeout: seconds ? seconds.seconds : nil) do
			active = false
			Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: false) do |win|
				active = win == thread.runner.display.x_do.active_window
			end
			active
		end
		is_active ? "0" : "1"
	end
end