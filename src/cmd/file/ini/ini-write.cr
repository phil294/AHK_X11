class Cmd::File::IniWrite < Cmd::Base
	def self.min_args; 4 end
	def self.max_args; 4 end
	def self.sets_error_level; true end
	def run(thread, args)
		value, filename, section, key = args
		begin
			ini = INI.parse(filename)
		rescue
			return "1"
		end
		if ! ini[section]?
			ini[section] = {} of String => String
		end
		ini[section][key] = value
		begin
			INI.build(filename, ini, space: true)
			return "0"
		rescue
			return "1"
		end
	end
end