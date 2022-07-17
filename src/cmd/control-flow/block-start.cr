require "../no-run"

class Cmd::ControlFlow::BlockStart < Cmd::Base
	include NoRun
	def self.name; "{"; end
end