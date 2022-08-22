require "./run"

class Cmd::Misc::RunWait < Cmd::Misc::Run
	@wait = true
end