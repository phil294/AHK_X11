require "./run"

class Cmd::Unix::RunWait < Cmd::Unix::Run
	@wait = true
end