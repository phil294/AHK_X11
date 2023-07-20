# FileRecycleEmpty [, DriveLetter]
class Cmd::File::FileRecycleEmpty < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 1 end
	def self.sets_error_level; true end
	def run(thread, args)
		status = Process.run("rm -rf ${XDG_DATA_HOME:-$HOME/.local/share}/Trash/*", shell: true).exit_code
		status == 0 ? "0" : "1"
	end
end