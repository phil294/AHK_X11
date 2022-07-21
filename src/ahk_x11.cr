require "./build/builder"
require "./run/runner"

fun main(argc : Int32, argv : UInt8**) : Int32
	# Enforce 4 threads because less than that break the program. For now, this is the
	# only way to enforce it. (1 = main, 2 = x11, 3 = gui, 4 = ? probably timer)
	LibC.setenv("CRYSTAL_WORKERS", "4", 1)
	Crystal.main(argc, argv)
end

if ! ARGV[0]?
	abort "Missing file argument.\nUsage:\n    ahk_x11 path/to/script.ahk"
end

ahk_str = File.read ARGV[0]
lines = ahk_str.split /\r?\n/

begin
	builder = Build::Builder.new
	builder.build lines
rescue e : Build::SyntaxException | Build::ParsingException
	# TODO msgbox
	abort e.message
end

start = builder.start
exit if ! start

begin
	runner = Run::Runner.new labels: builder.labels, escape_char: builder.escape_char
	runner.run hotkey_labels: builder.hotkey_labels, auto_execute_section: start
rescue e : Run::RuntimeException
	# TODO msgbox
	abort e.message
end
# TODO uncaught error handler? -> abort, and externalize abort from here and thread into something else

sleep # exiting is completely handled in runner