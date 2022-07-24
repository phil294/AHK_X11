require "../base"

class Cmd::Variable::EnvMult < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end

	def run(thread, args)
		var, mult_value = args
		current_value = thread.runner.get_var(var)
		pure_int = ! current_value.includes?('.') && ! mult_value.includes?('.')
		mult_value = mult_value.to_f?(strict: true) || 0
		current_value = current_value.to_f?(strict: true) || 0
		new_value = current_value * mult_value
		new_value = new_value.to_i if pure_int
		new_value = new_value.to_s
		thread.runner.set_var(var, new_value)
	end
end