class Cmd::Math::EnvSub < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end

	def run(thread, args)
		args[1] = "-#{args[1]}"
		EnvAdd.new(@line_no, @args).run(thread, args)
	end
end