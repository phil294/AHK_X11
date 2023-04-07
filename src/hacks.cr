# Place for syntax problems, workaround, missing stdlib methods etc.
# Every entry needs to be explained and should be avoided whenever possible.

lib LibC
	fun getuid : UidT
end

class Hacks
	# https://stackoverflow.com/q/67591891
	def self.username
		System::User.find_by(id: LibC.getuid.to_s).username
	end

	# Determine/return stdin *but if nothing is present right now, return immediately*.
	# Somehow this seems to be the only possible way. Peek or get_char are always blocking,
	# and fseek/ftell don't detect stdin.
	def self.get_all_stdin_if_available
		channel = Channel(Char | Nil).new
		spawn same_thread: true do
			c = STDIN.read_char
			channel.send(c)
		end
		select
		when c = channel.receive
			return nil if c.nil?
			return c + STDIN.gets_to_end
		when timeout(1.nanosecond)
			return nil
		end
	end

	# https://github.com/crystal-lang/crystal/issues/13297
	class_property fiber_on_unhandled_exception : Proc(Exception, Nil)?
	def self.set_fiber_on_unhandled_exception(&block : Exception -> Nil)
		@@fiber_on_unhandled_exception = block
	end
end

# https://github.com/crystal-lang/crystal/issues/13297
class Fiber
	# Code copied over and extended from stdlib
	def run
		GC.unlock_read
		@proc.call
	rescue ex
		if handler = Hacks.fiber_on_unhandled_exception
			handler.call ex
		else
			if name = @name
				STDERR.print "Unhandled exception in spawn (name: #{name}): "
			else
				STDERR.print "Unhandled exception in spawn: "
			end
			ex.inspect_with_backtrace(STDERR)
			STDERR.flush
		end
	ensure
		{% if flag?(:preview_mt) %}
			Crystal::Scheduler.enqueue_free_stack @stack
		{% elsif flag?(:interpreted) %}
			# For interpreted mode we don't need a new stack, the stack is held by the interpreter
		{% else %}
			Fiber.stack_pool.release(@stack)
		{% end %}

		# Remove the current fiber from the linked list
		Fiber.fibers.delete(self)

		# Delete the resume event if it was used by `yield` or `sleep`
		@resume_event.try &.free
		@timeout_event.try &.free
		@timeout_select_action = nil

		@alive = false
		Crystal::Scheduler.reschedule
	end
end