class Cmd::Math::EnvMath < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def self.sets_error_level; true end

	def run(thread, args)
		var = args[0]
		formula = args[1]? || ""
		formula = formula.gsub /\b[^0-9.()%\/*<>+-]\w*\b/ do |word|
			thread.get_var(word)
		end
		stdout_m = IO::Memory.new
		stderr_m = IO::Memory.new
		result = Process.run "awk", ["BEGIN {print #{formula}}"], output: stdout_m, error: stderr_m
		if result.exit_code != 0
			thread.runner.set_user_var var, ""
			return stderr_m.to_s
		end
		thread.runner.set_user_var var, stdout_m.to_s.strip
		return "0"
	end
end