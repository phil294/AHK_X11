class Cmd::ControlFlow::SetTimer < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def run(thread, args)
		label = args[0].downcase
		action = (args[1]? || "").downcase
		priority = (args[2]? || "").to_i? || 0
		timer = thread.runner.get_timer label
		case action
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
			period = action.to_i?
			raise Run::RuntimeException.new "invalid timer period" if ! period
			if ! timer
				timer = thread.runner.add_timer label, period.milliseconds, priority
			else
				timer.update period: period.milliseconds, priority: priority
			end
		end
	end
end