require "./no-run"

class Cmd::BlockEnd < Cmd::Base
	include NoRun
	def self.name; "}"; end
	def self.multi_command; true end
end