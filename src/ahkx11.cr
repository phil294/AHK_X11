require "./build"
require "./run"

if ! ARGV[0]?
	abort "Missing file argument.\nUsage:\n    ahkx11 path/to/script.ahk"
end

ahkstr = File.read ARGV[0]
ahkarr = ahkstr.split /\r?\n/

begin
	start = Builder.new.build ahkarr
rescue e : SyntaxException | ParsingException
	# TODO msgbox
	abort e.message
end
if ! start
	# TODO msgbox
	abort "No executable lines found"
end

Runner.new.run start