require "./build"
require "./run"

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

begin
	runner = Runner.new labels: builder.labels, auto_execute_section: builder.start, escape_char: builder.escape_char
	runner.run
rescue e : RuntimeException
	# TODO msgbox
	abort e.message
end