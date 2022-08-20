class Cmd::Variable::EnvAdd < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end

	def run(thread, args)
		var, add_value = args
		time_units = args[2]?
		
		current_value = thread.runner.get_user_var(var)
		pure_int = ! current_value.includes?('.') && ! add_value.includes?('.')
		add_value = add_value.to_f?(strict: true)

		if time_units
			new_value = ""
			if current_value.empty?
				current_time = Time.local
			else
				current_time = Time.parse_YYYYMMDDHH24MISS? current_value
			end
			if ! current_time.nil? && ! add_value.nil?
				add_value = case time_units.downcase
				when "days", "d"
					add_value.days
				when "seconds", "s"
					add_value.seconds
				when "minutes", "m"
					add_value.minutes
				when "hours", "h"
					add_value.hours
				else
					nil
				end
				if ! add_value.nil?
					new_value = (current_time + add_value).to_YYYYMMDDHH24MISS
				end
			end
		else
			current_value = current_value.to_f?(strict: true) || 0
			add_value = add_value || 0
			new_value = current_value + add_value
			new_value = new_value.to_i if pure_int
			new_value = new_value.to_s
		end
		
		thread.runner.set_user_var(var, new_value)
	end
end