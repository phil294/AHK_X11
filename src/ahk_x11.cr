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
	LibC.setenv("LC_ALL", "en_US.UTF-8", 1)
	Crystal.main(argc, argv)
end

Signal::HUP.trap do
	STDERR.puts "Received SIGHUB signal (probably by #SingleInstance from another ahkx11 script). Exit."
	::exit 129
end

HEADLESS = ! ENV["DISPLAY"]? || ENV["DISPLAY"].empty?

def build_error(msg)
	msg = "#{msg}\n\nThe program will exit."
	if ! HEADLESS
		gui = Run::Gui.new "AHK_X11"
		spawn gui.run
		gui.msgbox msg
	end
	abort msg
end
# TODO: fiber unhandled exception handler set to build_errow somehow?

def filename_to_path(filename)
	filename = filename[7..] if filename.starts_with?("file://")
	Path[filename].expand
end

script_file = nil
version = {{ read_file("./shard.yml").split("\n")[1][9..] }}
if ARGV[0]?
	if ARGV[0] == "-v" || ARGV[0] == "--version"
		puts "AHK_X11 version: #{version}\nTargets to partially implement Classic Windows AutoHotkey specification: v1.0.24 (2004). AutoHotkey is a scripting language."
		::exit
	elsif ARGV[0] == "-h" || ARGV[0] == "--help"
		puts "AHK_X11 is a Linux implementation for AutoHotkey classic version 1.0.24 (2004). Internal version: #{version}. Full up to date documentation can be found at https://phil294.github.io/AHK_X11/.\n\nPossible methods of invocation:\n\nahk_x11.AppImage \"path to script.ahk\"\nahk_x11.AppImage /dev/stdin <<< $'MsgBox, 1\\nMsgBox, 2'\nahk_x11.AppImage --repl\nahk_x11.AppImage --windowspy\nahk_x11.AppImage --compile \"path to script.ahk\" \"optional: output executable file path\"\n\nAlternatively, just run the program without arguments to open the graphical installer. Once installed, you should be able to run and/or compile any .ahk file in your file manager by selecting it from the right click context menu."
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
		begin
			ahk_str = File.read(script_file)
		rescue
			build_error "File '#{ARGV[0]}' could not be read."
		end
		lines = ahk_str.split(/\r?\n/)
	end
else
	lines = Compiler.new.extract.try &.split('\n')
	abort "Argument missing." if ! lines
	# Only needed for installer script, this can't (yet) really be part of ahk code. TODO: rm on exit
	File.write("/tmp/tmp_ahk_x11_logo.png", logo_blob)
end

begin
	builder = Build::Builder.new
	builder.build lines
rescue e : Build::SyntaxException | Build::ParsingException
	build_error e
end

begin
	runner = Run::Runner.new builder: builder, script_file: script_file, headless: HEADLESS
	runner.run
rescue e : Run::RuntimeException
	build_error e
end

sleep # exiting is completely handled in runner