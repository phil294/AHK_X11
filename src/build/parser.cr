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
		getter runner_settings = Run::RunnerSettings.new

		@block_comment = false
		@hotstring_default_options = ""

		def parse_into_cmds!(lines : Indexable(String))
			@cmds.clear
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
			{% if ! flag?(:release) %}
				puts "[debug] #{line_no}: #{line}" # TODO: externalize / use logger
			{% end %}
			match = line.strip
				.sub(/(^| |\t)#{@comment_flag}.*$/, "") # rm comments
				.match(/^\s*([^\s,]*)(\s*,?)(.*)$/).not_nil!
			first_word_case_sensitive = match[1]
			first_word = first_word_case_sensitive.downcase
			first_word_glue = match[2]
			args = match[3]
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
			# This is the "normal" case where 90% of all commands fall into. All other if-clauses
			# are special cases.
			elsif cmd_class
				csv_args = split_args(args, cmd_class.max_args + 1)
				if csv_args.size > cmd_class.max_args
					if cmd_class.multi_command
						# examples: if, ifequals, else, }, ifequals, ... can all have residue content.
						# split this line in two, add a new virtual line with the remainder.
						@cmds << cmd_class.new line_no, cmd_class.max_args > 0 ? csv_args[..cmd_class.max_args-1] : [] of String
						add_line csv_args[cmd_class.max_args], line_no
					else
						raise "'#{cmd_class.name}' accepts no arguments" if cmd_class.max_args == 0
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
			elsif first_word == "#persistent"
				@runner_settings.persistent = true
			elsif first_word == "#hotstring"
				if args[0..8].downcase == "endchars "
					str = Util::AhkString.parse_string(args[8..].strip, @runner_settings.escape_char, no_variable_substitution: true){}
					@runner_settings.hotstring_end_chars = str.chars
				else
					@hotstring_default_options = args.strip
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
			elsif first_word.includes?("::")
				label, instant_action = first_word_case_sensitive.split(/(?<=.)::/, limit: 2)
				if label.starts_with?(":") # Hotstring
					match = label.match(/^:([^:]*):([^:]+)$/)
					raise "Hotstring definition invalid or too complicated " if match.nil?
					_, options, abbrev = match
					@cmds << Cmd::ControlFlow::Label.new line_no, [label.downcase]
					hotstring = Run::Hotstring.new label.downcase, abbrev,
						options: @hotstring_default_options + options,
						escape_char: @runner_settings.escape_char
					@hotstrings << hotstring
					if ! instant_action.empty?
						end_char = hotstring.omit_ending_character ? "" : "%A_EndChar%"
						send = hotstring.auto_send_raw ? "SendRaw" : "Send"
						add_line "#{send}, #{instant_action}#{first_word_glue}#{args}#{end_char}", line_no
						add_line "Return", line_no
					end
				else # Hotkey
					@cmds << Cmd::ControlFlow::Label.new line_no, [label.downcase]
					@hotkeys << Run::Hotkey.new label.downcase, priority: 0
					if ! instant_action.empty?
						add_line "#{instant_action}#{first_word_glue}#{args}", line_no
						add_line "Return", line_no
					end
				end
			elsif first_word == "gui"
				# Gui accepts many subcommands. Instead of duplicating parsing logic into a generic
				# `Gui` cmd, instead join together (e.g. `GuiAdd`) and parse line again with that.
				# All subcommands exist as standalone commands and expect the gui id as 1st arg.
				split = split_args(args, 2)
				sub_instruction = split[0]? || ""
				rest_args = split[1]? || ""
				match = sub_instruction.match(/(?:(\S+)\s*:\s*)?(.*)/).not_nil!
				gui_id = match[1]? || "1"
				sub_cmd = match[2]
				raise "Gui subcommand missing" if sub_cmd.empty?
				comma = rest_args.empty? ? "" : ","
				add_line "Gui#{sub_cmd}, #{gui_id}#{comma} #{rest_args}", line_no
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
		 	args.split(/(?<!#{@runner_settings.escape_char}),/, limit).map do |arg|
				arg.strip.gsub(/(?<!#{@runner_settings.escape_char})#{@runner_settings.escape_char},/, ",")
			end
		end

	end
end