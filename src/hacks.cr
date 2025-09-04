# Place for syntax problems, workaround, missing stdlib methods etc.
# Every entry needs to be explained and should be avoided whenever possible.

lib LibC
	fun getuid : UidT
end

class Hacks
	# https://stackoverflow.com/q/67591891
	# TODO: why not `whoami`?
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

	# Crystal doesn't seem to support any such functionality?
	def self.is_utf8_file_no_bom(path)
		begin
			return Process.run("iconv", ["-f", "utf8", "-t", "utf8", path]).exit_code == 0 &&
				! `command -v file && file -b #{path}`.includes?("BOM")
		rescue
			return true
		end
	end
end

# https://github.com/crystal-lang/crystal/issues/13297
class Fiber
	OLD_NEW = method :new
	def self.new(*args, **opts, &block)
		OLD_NEW.call(*args, **opts) do
			block.call
		rescue ex
			if handler = Hacks.fiber_on_unhandled_exception
				handler.call(ex)
			else
				raise ex
			end
		end
	end
end

# DllCall:
# https://github.com/crystal-lang/crystal/issues/2800#issuecomment-2744568398
class Crystal::Loader
	def self.library_filename(libname : String) : String
		libname = "lib" + libname if ! libname.starts_with?("lib")
		libname += ".so" if ! libname.match /\.so\b/
		libname
	end
end
# DllCall:
# When building with musl, this is necessary because
# In /usr/lib/crystal/core/compiler/crystal/loader/unix.cr:220:10
# 220 | `#{Crystal::Compiler::DEFAULT_LINKER} -print-search-dirs`
# And cc is at least a symlink on all unix systems anyway (?)
class Crystal::Compiler DEFAULT_LINKER = "cc" end