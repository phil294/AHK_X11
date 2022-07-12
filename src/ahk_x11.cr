require "./build"
require "./runner"

if ! ARGV[0]?
	abort "Missing file argument.\nUsage:\n    ahk_x11 path/to/script.ahk"
end

ahkstr = File.read ARGV[0]
lines = ahkstr.split /\r?\n/

begin
	builder = Builder.new
	builder.build lines
rescue e : SyntaxException | ParsingException
	# TODO msgbox
	abort e.message
end

start = builder.start
exit if ! start

begin
	runner = Run::Runner.new labels: builder.labels, auto_execute_section: start, escape_char: builder.escape_char
rescue e : RuntimeException
	# TODO msgbox
	abort e.message
end