class Cmd::ControlFlow::Break < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 0 end
	# Where a `break` points to is already determined at build time (like all linking is).
	# The respective loop isn't saved though, so we query it here for finishing (resources etc.)
	def run(thread, args)
		innermost_loop = thread.loop_stack.last?
		# This can happen in edge cases with gosub/goto which are actually disallowed
		# at build time with win ahk. Here, it's simply undefined behavior.
		raise Run::RuntimeException.new "Trying to BREAK without a LOOP" if ! innermost_loop
		innermost_loop.finish(thread)
	end
end