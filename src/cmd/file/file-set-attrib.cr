require "./file-util"
class Cmd::File::FileSetAttrib < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 4 end
	def self.sets_error_level; true end
	def run(thread, args)
		attr = args[0]
		Util.match(args[1..]? || [] of ::String) do |match|
			on = off = toggle = false
			perm = ::File.directory?(match) ? 0o755 : 0o644
			attr.each_char do |c|
				case c.downcase
				when '+' then on = true
				when '-' then off = true
				when '^' then toggle = true
				when 'x'
					if on
						perm = 0o755
					elsif toggle
						perm = 0o755 if ! ::File.executable?(match)
					end
					on = off = toggle = false
				when 'n'
					on = off = toggle = false
				end
			end
			::File.chmod(match, perm)
		end
		"0"
	end
end