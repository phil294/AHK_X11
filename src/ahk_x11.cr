require "./build/builder"
require "./run/runner"

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
	runner = Run::Runner.new labels: builder.labels, hotkey_labels: builder.hotkey_labels, auto_execute_section: start, escape_char: builder.escape_char
rescue e : Run::RuntimeException
	# TODO msgbox
	abort e.message
end
# TODO uncaught error handler? -> abort, and externalize abort from here and thread into something else

sleep # exiting is completely handled in runner