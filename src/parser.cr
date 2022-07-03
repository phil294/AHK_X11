require "./cmd/**"

class ParsingException < Exception end

# parse lines into fully instantiated ahk commands with their respective arguments
# (includes syntax checks)
class Parser
	@cmd_class_by_name = { # TODO solve with macro
		"filecopy" => FileCopyCmd,
		"echo" => EchoCmd,
		"setenv" => SetEnvCmd,
		"ifequal" => IfEqualCmd,
		"{" => BlockStartCmd,
		"}" => BlockEndCmd,
		"else" => ElseCmd,
	} of String => Cmd.class
	# @cmd_class_by_name : Array(Cmd.class)
	# def initialize() TODO
	# 	@cmd_class_by_name = Cmd.all_subclasses
	# end

	@cmds = [] of Cmd

	def parse_into_cmds(lines : Array(String))
		@cmds = [] of Cmd
		lines.each_with_index do |line, line_no|
			begin
				add_line line, line_no
			rescue e : SyntaxException
				raise SyntaxException.new "Syntax Error in line #{line_no}: '#{e.message}'. Line content was: '#{line}'."
			end
		end
		@cmds
	end

	def add_line(line, line_no)
		match = line
			.sub(/(^| |\t);.*$/, "") # rm commments
			.match(/^\s*([^\s,]*)\s*,?(.*)$/).not_nil!
		first_word = match[1].downcase
		args = match[2]
		csv_args = [] of String

		return if first_word.empty?
		# Almost everything starts with a regular command, but there are
		# a few exceptions: if, assignments.
		cmd_class = @cmd_class_by_name[first_word]?
		if cmd_class
			csv_args = args.split(',', cmd_class.max_args + 1, remove_empty: true).map &.strip
			if csv_args.size > cmd_class.max_args
				if cmd_class.multi_command
					# examples: if, ifequals, else, }, ifequals, ... can all have residue content.
					# split this line in two, add a new virtual line with the remainder.
					@cmds << cmd_class.new line_no, csv_args[..cmd_class.max_args-1] # TODO what if max is 0?
					add_line csv_args[cmd_class.max_args], line_no
				else
					# attach the remainder again and pass as is to the arg
					# TODO also maybe only if allowed via flag? so that commands don't accidentally accept / combine too many arguments
					csv_args[cmd_class.max_args-1] += ",#{csv_args.pop}"
					@cmds << cmd_class.new line_no, csv_args
				end
			elsif csv_args.size < cmd_class.min_args
				raise SyntaxException.new "Line #{line_no}: Minimum arguments required is '#{cmd_class.min_args}', got '#{csv_args.size}'"
			else
				@cmds << cmd_class.new line_no, csv_args
			end
		elsif first_word == "if"
			split = args.split(/ |\n/, 3, remove_empty: true)
			case split[1]?
			when "="
				cmd_class = IfEqualCmd
			else
				raise ParsingException.new "Line #{line_no}: If condition '#{split[1]?}' is unknown"
			end
			csv_args = [split[0], split[2]? || ""]
			@cmds << cmd_class.new line_no, csv_args
		else
			split = args.split()
			if split[0]? == "="
				cmd_class = SetEnvCmd
				csv_args = [first_word, split[1]? || ""]
			else
				raise ParsingException.new "Line #{line_no}: Command '#{first_word}' not found"
			end
			@cmds << cmd_class.new line_no, csv_args
		end
	end
end