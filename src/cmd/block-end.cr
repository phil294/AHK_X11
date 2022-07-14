require "./no-run"

class BlockEndCmd < Cmd
	include NoRun
	def self.name; "}"; end
	def self.multi_command; true end
end