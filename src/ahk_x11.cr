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
rescue e : Cmd::SyntaxException | Build::ParsingException
	# TODO msgbox
	abort e.message
end

start = builder.start
exit if ! start

runner = Run::Runner.new labels: builder.labels, auto_execute_section: start, escape_char: builder.escape_char

sleep # exiting is completely handled in runner