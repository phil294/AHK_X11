require "./parser"
require "./linker"

class Builder
	@parser = Parser.new
	@linker = Linker.new
	getter start : Cmd? = nil
	getter labels = {} of String => Cmd
	getter escape_char = '`'

	def build(lines : Array(String))
		cmds = @parser.parse_into_cmds lines
		@escape_char = @parser.escape_char
		@linker.link! cmds
		@start = @linker.start
		@labels = @linker.labels
		nil
	end
end