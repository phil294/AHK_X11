# Quite similar to `deno compile` @ https://github.com/denoland/deno/pull/8539/files
class Compiler
	TRAILER = "AHK_SOUR"
	def compile(script_path, out_path)
		script = File.read(script_path)
		out_path = Path[script_path].stem if ! out_path
		bin_file = File.new(PROGRAM_NAME)
		out_file = File.new(out_path, "w")
		IO.copy(bin_file, out_file)
		out_file.write_string(script.to_slice)
		out_file.write_string(TRAILER.to_slice)
		out_file.write_bytes(bin_file.size)
		out_file.chmod(0o755)
		bin_file.close
		out_file.close
	end
	def extract
		bin_file = File.new(PROGRAM_NAME)
		bin_file.seek(-16, IO::Seek::End)
		if bin_file.gets(8) == TRAILER
			bin_size = bin_file.read_bytes(Int64)
			bin_file.seek(bin_size)
			bin_file.gets('\0', bin_file.size - bin_size - 16)
		end
	end
end