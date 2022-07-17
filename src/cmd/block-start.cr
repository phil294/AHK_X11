require "./no-run"

class Cmd::BlockStart < Cmd::Base
	include NoRun
	def self.name; "{"; end
end