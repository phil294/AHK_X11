require "../no-run"

class Cmd::ControlFlow::Else < Cmd::Base
	include NoRun
	def self.multi_command; true end
end