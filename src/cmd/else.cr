require "./no-run"

class ElseCmd < Cmd
	include NoRun
	def self.multi_command; true end
end