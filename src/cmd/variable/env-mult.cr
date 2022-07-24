require "../base"

class Cmd::Variable::EnvMult < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end

	def run(thread, args)
		var, mult_value = args
		mult_value = mult_value.to_f?(strict: true) || 0
		mult_value = mult_value.to_i if mult_value.round == mult_value
		current_value = thread.runner.get_var(var).to_f?(strict: true) || 0
		current_value = current_value.to_i if current_value.round == current_value
		new_value = (current_value * mult_value).to_s
		thread.runner.set_var(var, new_value)
	end
end