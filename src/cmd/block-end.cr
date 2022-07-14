require "./no-run"

module Cmd
	class BlockEnd < Base
		include NoRun
		def self.name; "}"; end
		def self.multi_command; true end
	end
end