require "tasker"

module Run
	private class Timer
		@task : Tasker::Repeat(Thread)?
		def initialize(@runner : Run::Runner, @cmd : Cmd, @period : Time::Span, @priority : Int32)
			update
		end
		def cancel
			if task = @task
				task.cancel
				@task = nil
			end
		end
		def update(@period = @period, @priority = @priority)
			# there's also @task.resume but that wouldn't reset the timer
			cancel
			@task = Tasker.every(@period) do
				@runner.spawn_thread @cmd, @priority
			end
		end
	end
end