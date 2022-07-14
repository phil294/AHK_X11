require "./no-run"

class ElseCmd < Cmd
	include NoRun
	def self.name; "else"; end
	def self.multi_command; true end
end