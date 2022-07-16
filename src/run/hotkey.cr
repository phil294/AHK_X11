module Run
	class Hotkey
		getter runner : Run::Runner
		getter cmd : Cmd::Base
		getter label : String
		def initialize(@runner, @cmd, @label)
		end
	end
end