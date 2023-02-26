require "ini"
# IniRead, OutputVar, Filename, Section, Key [, Default]
class Cmd::File::IniRead < Cmd::Base
	def self.min_args; 4 end
	def self.max_args; 5 end
	def run(thread, args)
		out_var, filename, section, key = args
		default = args[4]? || "ERROR"
		begin
			ini = INI.parse(::File.new(filename))
		rescue
		end
		value = ini[section]?.try &.[key]? if ini
		value ||= default
		thread.runner.set_user_var(out_var, value)
	end
end