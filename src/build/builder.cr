require "./parser"
require "./linker"

module Build
	class Builder
		@parser = Parser.new
		@linker = Linker.new
		getter start : Cmd::Base? = nil
		getter labels = {} of String => Cmd::Base
		getter hotkey_labels = [] of String
		getter escape_char = '`'
		getter runner_settings = Run::RunnerSettings.new

		def build(lines : Array(String))
			@parser.parse_into_cmds! lines
			@hotkey_labels = @parser.hotkey_labels
			@escape_char = @parser.escape_char
			@linker.link! @parser.cmds
			@start = @linker.start
			@labels = @linker.labels
			@runner_settings = @linker.runner_settings
			nil
		end
	end

	class SyntaxException < Exception end
end