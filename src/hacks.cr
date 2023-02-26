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
end