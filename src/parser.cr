require "./cmd/cmd"
require "./cmd/echo"
require "./cmd/set-env"
require "./cmd/if-equal"
require "./cmd/file/file_copy"

class ParsingException < Exception end

# parse lines into fully instantiated ahk commands with their respective arguments
# (includes syntax checks)
class Parser
	@cmd_class_by_name = { # TODO solve with macro
		"filecopy" => FileCopyCmd,
		"echo" => EchoCmd,
		"setenv" => SetEnvCmd,
		"ifequal" => IfEqualCmd,
	} of String => Cmd.class

	def parse_into_cmds(lines : Array(String))
		cmds = [] of Cmd
		lines.each_with_index do |line, line_no|
			from = 0
			while line[from]?.try &.whitespace?
				from += 1
			end
			to = from + 1
			while line[to+1]? && ! line[to+1].whitespace? && line[to+1] != ','
				to += 1
			end
			first_word = line[from..to].downcase
			while line[to+1]?.try &.whitespace?
				to += 1
			end
			to += 1 if line[to+1] == ','
			
			args = line[to+1..]
			csv_args = [] of String

			# Almost everything starts with a regular command, but there are
			# a few exceptions: if, assignments.
			cmd_name = first_word
			cmd_class = @cmd_class_by_name[first_word]?
			if cmd_class
				csv_args = args.split(',', cmd_class.max_args).map &.strip
				if csv_args.size < cmd_class.min_args
					raise SyntaxException.new "Line #{line_no}: Minimum arguments required is '#{cmd_class.min_args}', got '#{csv_args.size}'"
				end
			elsif first_word == "if"
				split = args.split(/ |\n/, 3, remove_empty: true)
				case split[1]?
				when "="
					cmd_class = IfEqualCmd
					cmd_name = "ifequal"
				else
					raise ParsingException.new "Line #{line_no}: If condition '#{split[1]?}' is unknown"
				end
				csv_args = [split[0], split[2]]
			else
				split = args.split()
				if split[0]? == "="
					cmd_class = SetEnvCmd
					cmd_name = "setenv"
					csv_args = [first_word, split[1]? || ""]
				else
					raise ParsingException.new "Line #{line_no}: Command '#{first_word}' not found"
				end
			end

			begin
				cmd = cmd_class.new csv_args
			rescue e : SyntaxException
				raise SyntaxException.new "Syntax Error in line #{line_no} for command '#{cmd_name}': #{e.message}"
			end
			cmd.name = cmd_name # possible to determine at runtime without this field?
			cmds << cmd
		end
		cmds
	end
end