require "./global/*"
require "./build/builder"
require "./run/runner"
require "./compiler"
require "./logo"

fun main(argc : Int32, argv : UInt8**) : Int32
	# It's also possible to run everything *without* `preview_mt` and spawn threads manually instead.
	# This is mostly complete in the `gui-without-preview_mt` branch but because Channels don't work
	# in MT, this needs suboptimal workarounds. Also, in that branch, gui glabel actions aren't
	# working because the gui code is expected to modify the threads array from the main thread...
	# It's all possible but rather ugly, so I went with MT for now.
	#
	# Enforce 4 threads because less than that break the program. For now, this is the
	# only way to enforce it. (1 = main, 2 = x11, 3 = gui, 4 = ? probably timer)
	LibC.setenv("CRYSTAL_WORKERS", "4", 1)
	# https://github.com/crystal-lang/crystal/issues/11952#issuecomment-1216955886
	LibC.setenv("LC_ALL", "en_US.UTF-8", 1)
	Crystal.main(argc, argv)
end

Signal::HUP.trap do
	STDERR.puts "Received SIGHUB signal (probably by #SingleInstance from another ahkx11 script). Exit."
	::exit 129
end

HEADLESS = ! ENV["DISPLAY"]?

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

script_file = nil
if ARGV[0]?
	if ARGV[0] == "--repl"
		lines = ["#Persistent"]
	elsif ARGV[0] == "--compile"
		build_error "Syntax: ahk_x11 --compile FILE_NAME [OUTPUT_FILENAME]" if ARGV.size < 2
		Compiler.new.compile(ARGV[1], ARGV[2]?)
		::exit
	else
		script_file = Path[ARGV[0]].expand
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
	File.delete?("/tmp/tmp_ahk_x11_logo.png") # ensure the right permission
	# Only needed for installer script, this can't (yet) really be part of ahk code. TODO: rm on exit
	File.write("/tmp/tmp_ahk_x11_logo.png", logo_blob)
end

begin
	builder = Build::Builder.new
	builder.build lines
rescue e : Build::SyntaxException | Build::ParsingException
	build_error e.message
end

begin
	runner = Run::Runner.new builder: builder, script_file: script_file, headless: HEADLESS
	runner.run
rescue e : Run::RuntimeException
	build_error e.message
end

sleep # exiting is completely handled in runner