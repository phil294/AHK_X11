require "../base"

class Cmd::ControlFlow::SetTimer < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def run(thread)
		label = thread.runner.str(@args[0])
		timer = thread.runner.get_timer label
		priority = thread.runner.str(@args[2]? || "").to_i?(strict: true) || 0
		case v = thread.runner.str(@args[1]? || "").downcase
		when "on", ""
			if ! timer
				timer = thread.runner.add_timer label, 250.milliseconds, priority
			else
				timer.update
			end
		when "off"
			timer = thread.runner.add_timer label, 250.milliseconds, priority if ! timer
			timer.cancel
		else
			period = v.to_i?(strict: true)
			raise "invalid timer period" if ! period
			if ! timer
				timer = thread.runner.add_timer label, period.milliseconds, priority
			else
				timer.update period: period.milliseconds, priority: priority
			end
		end
	end
end