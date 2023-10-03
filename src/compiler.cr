# Quite similar to `deno compile` @ https://github.com/denoland/deno/pull/8539/files
class Compiler
	TRAILER = "AHK_SOUR"
	def initialize
		bin_path = ENV["APPIMAGE"]?
		@is_appimage = !! bin_path
		if ! bin_path || bin_path.empty?
			bin_path = Process.executable_path
			raise "Cannot determine binary path" if ! bin_path
		end
		@bin_file = File.new(bin_path)
	end
	def finalize
		@bin_file.close
	end
	def compile(script_path, out_path)
		if ! @is_appimage
			STDERR.puts "WARNING: AHK_X11 Binary does not appear to be inside an AppImage. Compilation will succeed but the resulting standalone program will not be very portable as dependencies are not bundled. This means that it may not run on other systems, or may fail to run on your system in the future. It is highly recommended you download the official ahk_x11.AppImage file instead, or add the packaging step to your build process (check ahk_x11's latest build instructions)."
		end
		script = File.read(script_path)
		out_path = script_path.stem if ! out_path
		out_file = File.new(out_path, "w")
		IO.copy(@bin_file, out_file)
		out_file.write_string(script.to_slice)
		out_file.write_string(TRAILER.to_slice)
		out_file.write_bytes(@bin_file.size)
		out_file.chmod(0o755)
		out_file.close
	end
	def extract
		@bin_file.seek(-16, IO::Seek::End)
		if @bin_file.gets(8) == TRAILER
			bin_size = @bin_file.read_bytes(Int64)
			@bin_file.seek(bin_size)
			@bin_file.gets('\0', @bin_file.size - bin_size - 16)
		end
	end
end