module Run
	class Hotkey
		getter runner : Run::Runner
		getter key_str : String
		property cmd : Cmd::Base
		property priority : Int32
		property active : Bool
		def initialize(@runner, @cmd, @key_str, *, @priority, @active = true)
		end
		def trigger
			@runner.add_thread @cmd, @priority
		end
	end
end