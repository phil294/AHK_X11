class Cmd::File::IniWrite < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def self.sets_error_level; true end
	def run(thread, args)
		filename, section = args
		key = args[2]?
		begin
			ini = INI.parse(filename)
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
			ini[section].delete_at(key) # TODO: !/? ?
		else
			ini.delete_at(section) # TODO:
		end
		begin
			INI.build(filename, ini, space: true)
			return "0"
		rescue
			return "1"
		end
	end
end