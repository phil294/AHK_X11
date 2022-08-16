require "./global/*"
require "./build/builder"
require "./run/runner"

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
	Crystal.main(argc, argv)
end

if ! ARGV[0]?
	abort "Missing file argument.\nUsage:\n    ahk_x11 path/to/script.ahk"
end

def build_error(msg)
	msg = "#{msg}\n\nThe program will exit."
	gui = Run::Gui.new
	spawn gui.run
	gui.msgbox msg
	abort msg
end
# TODO: fiber unhandled exception handler set to build_errow somehow?

begin
	ahk_str = File.read ARGV[0]
rescue
	build_error "File '#{ARGV[0]}' could not be read."
end
lines = ahk_str.split /\r?\n/

begin
	builder = Build::Builder.new
	builder.build lines
rescue e : Build::SyntaxException | Build::ParsingException
	build_error e.message
end

start = builder.start
exit if ! start

begin
	runner = Run::Runner.new labels: builder.labels, escape_char: builder.escape_char, settings: builder.runner_settings
	runner.run hotkeys: builder.hotkeys, hotstrings: builder.hotstrings, auto_execute_section: start
rescue e : Run::RuntimeException
	build_error e.message
end

sleep # exiting is completely handled in runner