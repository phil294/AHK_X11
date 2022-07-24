require "../base"

class Cmd::Variable::EnvDiv < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end

	def run(thread, args)
		var, div_value = args
		div_value = div_value.to_f?(strict: true) || 0
		current_value = thread.runner.get_var(var).to_f?(strict: true) || 0
		new_value = current_value / div_value
		if div_value.round == div_value && current_value.round == current_value
			new_value = new_value.to_i
		end
		thread.runner.set_var(var, new_value.to_s)
	end
end