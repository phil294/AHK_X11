require "./no-run"

module Cmd
	class Else < Base
		include NoRun
		def self.multi_command; true end
	end
end