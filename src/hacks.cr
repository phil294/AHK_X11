# Place for syntax problems, workaround, missing stdlib methods etc.
# Every entry needs to be explained and should be avoided whenever possible.

lib LibC
	# Query user name: https://stackoverflow.com/q/67591891
	fun getuid : UidT
end

class Hacks
	def self.username
		System::User.find_by(id: LibC.getuid.to_s).username
	end
end