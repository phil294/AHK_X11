class Cmd::File::FileRead < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var, filename = args
		begin
			txt = ::File.read(filename)
			thread.runner.set_user_var(out_var, txt)
			"0"
		rescue e
			"1"
		end
	end
end