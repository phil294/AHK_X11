require "./parser"
require "./linker"

module Build
	class Builder
		getter parser = Parser.new
		getter linker = Linker.new
		getter start : Cmd::Base? = nil
		getter labels = {} of String => Cmd::Base
		getter hotkey_definitions = [] of Run::HotkeyDefinition
		getter hotstrings = [] of Run::Hotstring
		getter runner_settings = Run::RunnerSettings.new

		def build(lines : Indexable(String))
			@parser.parse_into_cmds! lines
			@hotkey_definitions = @parser.hotkey_definitions
			@hotstrings = @parser.hotstrings
			@runner_settings = @parser.runner_settings

			@linker.link! @parser.cmds
			@start = @linker.start
			@labels = @linker.labels

			# This can only really be done once the linker has finished
			@hotstrings.each do |hotstring|
				hotstring.cmd = @labels[hotstring.label.downcase]
			end

			nil
		end
	end

	class SyntaxException < Exception end
end