require "./global/*"
require "./build/builder"
require "./run/runner"
require "./compiler"
require "./logo"
require "./hacks"

fun main(argc : Int32, argv : UInt8**) : Int32
	# It's also possible to run everything *without* `preview_mt` and spawn threads manually instead.
	# This is mostly complete in the `gui-without-preview_mt` branch but because Channels don't work
	# in MT, this needs suboptimal workarounds. Also, in that branch, gui glabel actions aren't
	# working because the gui code is expected to modify the threads array from the main thread...
	# It's all possible but rather ugly, so I went with MT for now.
	#
	# Enforce 3 threads because less than that break the program. For now, this is the
	# only way to enforce it. (1 = main, 2 = gui, 3 = ? probably timer)
	LibC.setenv("CRYSTAL_WORKERS", "3", 1)

	# https://github.com/crystal-lang/crystal/issues/11952#issuecomment-1216955886
	LibC.setenv("ahk_x11_LC_ALL_backup", ENV["LC_ALL"]? || "en_US.UTF-8", 1)
	LibC.setenv("LC_ALL", "en_US.UTF-8", 1)

	Crystal.main(argc, argv)
end

Signal::HUP.trap do
	STDERR.puts "Received SIGHUB signal (probably by #SingleInstance from another ahkx11 script). Exit."
	::exit 129
end

HEADLESS = ! ENV["DISPLAY"]? || ENV["DISPLAY"].empty?

def build_error(msg)
	if msg.is_a?(Exception)
		msg.inspect_with_backtrace(STDERR)
	else
		STDERR.puts msg
	end
	STDERR.flush
	msg = "#{msg}\n\nThe program will exit."
	if ! HEADLESS
		gtk = Run::Gtk.new "AHK_X11"
		spawn gtk.run
		gtk.msgbox msg
	end
	# Sometimes somehow Crystal::AtExitHandlers never finish so we cannot use abort/exit
	Process.exit(1)
end

Hacks.set_fiber_on_unhandled_exception do |ex|
	ex = Exception.new("Internal AHK_X11 error :-(\n\nPlease report it to https://github.com/phil294/ahk_x11/issues.\n\nDetails:\n#{ex.message}\n#{ex.backtrace}", ex.cause)
	STDERR.print "Unhandled exception in spawn: "
	build_error(ex)
end

if ENV["XDG_SESSION_TYPE"]? != "x11"
	STDERR.puts "WARNING: Your system seems to NOT be running X11 but '#{ENV["XDG_SESSION_TYPE"]? || "undefined"}'. A LOT of things won't work (yet), such as hotkeys, sending keys, and window operations."
end

def filename_to_path(filename)
	filename = filename[7..] if filename.starts_with?("file://")
	Path[filename].expand
end

script_file = nil
version = {{ read_file("./shard.yml").split("\n")[1][9..] }}
lines = Compiler.new.extract.try &.split('\n')
is_compiled = !! lines
if ! lines
	# Only needed for installer script, this can't (yet) really be part of ahk code. TODO: rm on exit
	File.write("/tmp/tmp_ahk_x11_logo.png", logo_blob)
	if ARGV[0]?
		if ARGV[0] == "-v" || ARGV[0] == "--version"
			puts "AHK_X11 version: #{version}\nTargets to partially implement Classic Windows AutoHotkey specification: v1.0.24 (2004). AutoHotkey is a scripting language."
			::exit
		elsif ARGV[0] == "-h" || ARGV[0] == "--help"
			puts "AHK_X11 is a Linux implementation for AutoHotkey classic version 1.0.24 (2004). Internal version: #{version}. Full up to date documentation can be found at https://phil294.github.io/AHK_X11/.\n\nPossible methods of invocation:\n\nahk_x11.AppImage \"path to script.ahk\"\nahk_x11.AppImage <<< $'MsgBox, 1\\nMsgBox, 2'\nahk_x11.AppImage --repl\nahk_x11.AppImage --windowspy\nahk_x11.AppImage --compile \"path to script.ahk\" \"optional: output executable file path\"\n\nAlternatively, just run the program without arguments to open the graphical installer. Once installed, you should be able to run and/or compile any .ahk file in your file manager by selecting it from the right click context menu."
			::exit
		elsif ARGV[0] == "--repl"
			lines = ["#Persistent"]
		elsif ARGV[0] == "--windowspy"
			lines = {{ read_file("./src/window-spy.ahk").split("\n") }}
		elsif ARGV[0] == "--compile"
			build_error "Syntax: ahk_x11 --compile FILE_NAME [OUTPUT_FILENAME]" if ARGV.size < 2
			Compiler.new.compile(filename_to_path(ARGV[1]), ARGV[2]? ? filename_to_path(ARGV[2]) : nil)
			::exit
		else
			script_file = filename_to_path(ARGV[0])
			if ! Hacks.is_utf8_file_no_bom(script_file.to_s)
				build_error "File '#{ARGV[0]}' does not appear to be a valid NO-BOM UTF-8 file! Other encodings aren't supported currently, sorry."
			end
			begin
				ahk_str = File.read(script_file)
			rescue
				build_error "File '#{ARGV[0]}' could not be read."
			end
			lines = ahk_str.split(/\r?\n/)
		end
	else
		stdin = Hacks.get_all_stdin_if_available
		if stdin
			lines = stdin.split('\n')
		else
			lines = {{ read_file("./src/installer.ahk").split("\n") }}
		end
	end
end

begin
	builder = Build::Builder.new
	builder.build lines
rescue e : Build::SyntaxException | Build::ParsingException
	build_error e
end

begin
	runner = Run::Runner.new builder: builder, script_file: script_file, is_compiled: is_compiled, headless: HEADLESS
	runner.run
rescue e : Run::RuntimeException
	build_error e
end

sleep # exiting is completely handled in runner