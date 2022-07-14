require "./parser"
require "./linker"

module Build
	class Builder
		@parser = Parser.new
		@linker = Linker.new
		getter start : Cmd::Base? = nil
		getter labels = {} of String => Cmd::Base
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
end