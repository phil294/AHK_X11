require "./run"

# RunWait, Target [, WorkingDir, Max|Min|Hide|UseErrorLevel, OutputVarPID, OutputVarStdout, OutputVarStderr]
class Cmd::Misc::RunWait < Cmd::Misc::Run
	@wait = true
end