require "../cmd/**"
require "../run/hotstring"

module Build
	class ParsingException < Exception end

	# parse lines into fully instantiated ahk commands with their respective arguments
	# (includes syntax checks)
	class Parser
		@@cmd_class_by_name : Hash(String, Cmd::Base.class)
		@@cmd_class_by_name = Cmd::Base.all_subclasses
			.reduce({} of String => Cmd::Base.class) do |acc, cmd_class|
				acc[cmd_class.name] = cmd_class
				acc
			end

		getter cmds = [] of Cmd::Base
		getter hotkeys = [] of Run::Hotkey
		getter hotstrings = [] of Run::Hotstring
		getter comment_flag = ";"
		getter escape_char = '`'

		@block_comment = false

		def parse_into_cmds!(lines : Array(String))
			lines.each_with_index do |line, line_no|
				begin
					add_line line, line_no
				rescue e
					{% if ! flag?(:release) %}
						puts "[debug]", e.inspect_with_backtrace
					{% end %}
					raise SyntaxException.new "Syntax Error in line #{line_no+1}:\n#{e.message}.\n\nLine content was: '#{line}'."
				end
			end
			raise SyntaxException.new "Missing */" if @block_comment
		end

		def add_line(line, line_no)
			match = line
				.sub(/(^| |\t)#{@comment_flag}.*$/, "") # rm comments
				.match(/^\s*([^\s,]*)\s*,?(.*)$/).not_nil!
			first_word = match[1].downcase
			args = match[2]
			csv_args = [] of String

			return if first_word.empty?
			# Almost everything starts with a regular command, but there are
			# a few exceptions: if, assignments.
			cmd_class = @@cmd_class_by_name[first_word]?
			if first_word == "/*"
				@block_comment = true
			elsif first_word == "*/"
				raise "Unexpected */" if ! @block_comment
				@block_comment = false
			elsif @block_comment
				#
			elsif cmd_class
				csv_args = split_args(args, cmd_class.max_args + 1)
				if csv_args.size > cmd_class.max_args
					if cmd_class.multi_command
						# examples: if, ifequals, else, }, ifequals, ... can all have residue content.
						# split this line in two, add a new virtual line with the remainder.
						@cmds << cmd_class.new line_no, cmd_class.max_args > 0 ? csv_args[..cmd_class.max_args-1] : [] of String
						add_line csv_args[cmd_class.max_args], line_no
					else
						# attach the remainder again and pass as is to the arg
						# TODO: also maybe only if allowed via flag? so that commands don't accidentally accept / combine too many arguments
						# TODO: spacing can wrongly get lost / added here because of the .strip + add ", " which may not add up
						csv_args[cmd_class.max_args-1] += ", #{csv_args.pop}"
						@cmds << cmd_class.new line_no, csv_args
					end
				elsif csv_args.size < cmd_class.min_args
					raise "Minimum arguments required for '#{cmd_class.name}' is '#{cmd_class.min_args}', got '#{csv_args.size}'"
				else
					@cmds << cmd_class.new line_no, csv_args
				end
			elsif first_word == "if"
				split = args.split(/ |\n/, 3, remove_empty: true)
				case split[1]?
				when "="
					cmd_class = Cmd::ControlFlow::IfEqual
				else
					raise "If condition '#{split[1]?}' is unknown"
				end
				csv_args = [split[0], split[2]? || ""]
				@cmds << cmd_class.new line_no, csv_args
			elsif first_word.ends_with?("::")
				if first_word.starts_with?(":")
					match = first_word.match(/^(:([^:]*):([^:]+))::$/)
					raise "Hotstring definition invalid or too complicated " if match.nil?
					_, label, options, abbrev = match
					@cmds << Cmd::ControlFlow::Label.new line_no, [label]
					hotstring = Run::Hotstring.new label, abbrev
					hotstring.immediate = true if options == "*"
					@hotstrings << hotstring
				else
					label = first_word[...-2]
					@cmds << Cmd::ControlFlow::Label.new line_no, [label]
					@hotkeys << Run::Hotkey.new label, priority: 0
				end
			elsif first_word.ends_with?(':')
				@cmds << Cmd::ControlFlow::Label.new line_no, [first_word[...-1]]
			elsif first_word.ends_with?("++")
				@cmds << Cmd::Variable::EnvAdd.new line_no, [first_word[...-2], "1"]
			elsif first_word.starts_with?("++")
				@cmds << Cmd::Variable::EnvAdd.new line_no, [first_word[2..], "1"]
			elsif first_word.ends_with?("--")
				@cmds << Cmd::Variable::EnvSub.new line_no, [first_word[...-2], "1"]
			elsif first_word.starts_with?("--")
				@cmds << Cmd::Variable::EnvSub.new line_no, [first_word[2..], "1"]
			else
				split = args.split(2)
				second_word, more_args = split[0]?, split[1]? || ""
				csv_args = [first_word, *split_args(more_args)]
				case second_word
				when "="
					cmd_class = Cmd::Variable::SetEnv
				when "+="
					cmd_class = Cmd::Variable::EnvAdd
					raise "Add value missing for '+=' expression" if ! csv_args[1]?
				when "-="
					cmd_class = Cmd::Variable::EnvSub
					raise "Sub value missing for '-=' expression" if ! csv_args[1]?
				when "*="
					cmd_class = Cmd::Variable::EnvMult
					raise "Mult value missing for '*=' expression" if ! csv_args[1]?
				when "/="
					cmd_class = Cmd::Variable::EnvDiv
					raise "Div value missing for '/=' expression" if ! csv_args[1]?
				else
					raise "Command '#{first_word}' not found"
				end
				@cmds << cmd_class.new line_no, csv_args
			end
		end

		def split_args(args, limit = nil)
			if args.empty?
				return [] of String
			end
		 	args.split(/(?<!#{@escape_char}),/, limit).map do |arg|
				arg.strip.gsub(/(?<!#{@escape_char})#{@escape_char},/, ",")
			end
		end

	end
end