require "./no-run"

class BlockStartCmd < Cmd
	include NoRun
	def self.name; "{"; end
end