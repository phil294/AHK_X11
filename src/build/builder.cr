require "./parser"
require "./linker"

module Build
	class Builder
		getter parser = Parser.new
		getter linker = Linker.new
		getter start : Cmd::Base? = nil
		getter labels = {} of String => Cmd::Base
		getter hotkeys = [] of Run::Hotkey
		getter hotstrings = [] of Run::Hotstring
		getter runner_settings = Run::RunnerSettings.new

		def build(lines : Indexable(String))
			@parser.parse_into_cmds! lines
			@hotkeys = @parser.hotkeys
			@hotstrings = @parser.hotstrings
			@runner_settings = @parser.runner_settings

			@linker.link! @parser.cmds
			@start = @linker.start
			@labels = @linker.labels

			nil
		end
	end

	class SyntaxException < Exception end
end