require "./build"
require "./run"

if ! ARGV[0]?
	abort "Missing file argument.\nUsage:\n    ahk_x11 path/to/script.ahk"
end

ahkstr = File.read ARGV[0]
ahkarr = ahkstr.split /\r?\n/

begin
	ctx = Builder.new.build ahkarr
rescue e : SyntaxException | ParsingException
	# TODO msgbox
	abort e.message
end

begin
	Runner.new(ctx).run
rescue e : RuntimeException
	# TODO msgbox
	abort e.message
end