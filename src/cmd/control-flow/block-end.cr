require "../no-run"

class Cmd::ControlFlow::BlockEnd < Cmd::Base
	include NoRun
	def self.name; "}"; end
	def self.multi_command; true end
end