require "./build"
require "./run"

# test code
ahk_script = [
	"Echo some te,,,xt",
	" 	 filecopy a*,  aout ,  ",
]

begin
	start = Builder.new.build ahk_script
rescue e : SyntaxException | ParsingException
	# TODO msgbox
	abort e.message
end
if ! start
	# TODO msgbox
	abort "No executable lines found"
end

Runner.new.run start