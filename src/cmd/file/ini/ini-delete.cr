require "ini"
# IniDelete, Filename, Section [, Key]
class Cmd::File::IniDelete < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def self.sets_error_level; true end
	def run(thread, args)
		filename, section = args
		key = args[2]?
		begin
			ini = INI.parse(::File.new(filename))
		rescue
			return "1"
		end
		if ! ini[section]?
			return "1"
		end
		if key
			if ! ini[section][key]?
				return "1"
			end
			ini[section].delete(key)
		else
			ini.delete(section)
		end
		begin
			INI.build(::File.new(filename, "w"), ini, space: true)
			return "0"
		rescue e
			return "1"
		end
	end
end