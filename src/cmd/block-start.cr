require "./no-run"

module Cmd
	class BlockStart < Base
		include NoRun
		def self.name; "{"; end
	end
end