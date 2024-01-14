require "../cmd/**"
require "../run/display/hotstring"
require "../run/key-combination"

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
		# TODO: several classes might be better put in neither run nor build folder
		getter hotkey_definitions = [] of Run::HotkeyDefinition
		getter hotstrings = [] of Run::Hotstring
		getter comment_flag = ";"
		getter runner_settings = Run::RunnerSettings.new

		@block_comment = false
		@hotstring_default_options = ""
		@already_included = [] of Path

		def parse_into_cmds!(lines : Indexable(String))
			@cmds.clear
			lines.each_with_index do |line, line_no|
				begin
					add_line line, line_no
				rescue e
					{% if ! flag?(:release) %}
						e.inspect_with_backtrace(STDERR)
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
			line_content = line
				.sub(/(^| |\t)#{@comment_flag}.*$/, "") # rm comments
				.strip
			match = line_content
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
				csv_args = split_args(args, cmd_class.multi_command ? cmd_class.max_args + 1 : cmd_class.max_args)
				if csv_args.size < cmd_class.min_args
					raise "Minimum arguments required for '#{cmd_class.name}' is '#{cmd_class.min_args}', got '#{csv_args.size}'"
				elsif csv_args.size > cmd_class.max_args
					# multi command, examples: if, ifequals, else, }, ifequals, ... can all have residue content.
					# split this line in two, add a new virtual line with the remainder.
					@cmds << cmd_class.new line_no, cmd_class.max_args > 0 ? csv_args[..cmd_class.max_args-1] : [] of String
					add_line csv_args[cmd_class.max_args], line_no
				else
					@cmds << cmd_class.new line_no, csv_args
				end
			elsif first_word == "#persistent"
				@runner_settings.persistent = true
			elsif first_word == "#singleinstance"
				param = args.strip.downcase
				@runner_settings.single_instance = param == "force" ? Run::SingleInstance::Force : param == "ignore" ? Run::SingleInstance::Ignore : param == "off" ? Run::SingleInstance::Off : param == "prompt" ? Run::SingleInstance::Prompt : nil
			elsif first_word == "#hotstring"
				if args[0..8].downcase == "endchars "
					str = Util::AhkString.parse_string(args[8..].strip, @runner_settings.escape_char, no_variable_substitution: true){}
					@runner_settings.hotstring_end_chars = str.chars
				else
					@hotstring_default_options = args.strip
				end
			elsif first_word == "#requires" # noop for ahk discord bot. Command is v1.1.33+.
			elsif first_word.starts_with?("#include")
				path = Path[args].expand
				if first_word != "#includeagain"
					return if @already_included.includes?(path)
				end
				@already_included << path
				i = -1
				File.new(path).each_line do |line|
					i += 1
					begin
						add_line line, i
					rescue e
						raise Exception.new ((e.message || "") + "\n#Include line: #{i}"), e.cause
					end
				end
			# fixme: change to something cross os-portable?
			elsif first_word == "#inputdevice"
				param = args.strip.downcase
				@runner_settings.input_interface = param == "xtest" ? Run::InputInterface::XTest : param == "xgrab" ? Run::InputInterface::XGrab : param == "evdev" ? Run::InputInterface::Evdev : param == "off" ? Run::InputInterface::Off : nil
			elsif first_word.starts_with?("#maxthreadsperhotkey")
				@runner_settings.max_threads_per_hotkey = args.to_u8? || 1_u8
				raise "#MaxThreadsPerHotkey maximum value is 20" if @runner_settings.max_threads_per_hotkey > 20
			elsif first_word == "#notrayicon"
				@runner_settings.no_tray_icon = true
			elsif first_word == "#xgrabroot"
				@runner_settings.x11_grab_from_root = true
			elsif line.starts_with?("#!") && line_no == 0 # hashbang
			elsif first_word == "#noenv"
			elsif first_word == "if"
				split = args.split(/ |\n/, 3, remove_empty: true)
				var_name = split[0]
				operator = split[1]? || ""
				arg2 = split[2]? || ""
				cmd_class = case operator
				when "=" then Cmd::ControlFlow::IfEqual
				when "<>", "!=" then Cmd::ControlFlow::IfNotEqual
				when ">" then Cmd::ControlFlow::IfGreater
				when ">=" then Cmd::ControlFlow::IfGreaterOrEqual
				when "<" then Cmd::ControlFlow::IfLess
				when "<=" then Cmd::ControlFlow::IfLessOrEqual
				when "between" then Cmd::ControlFlow::IfBetween
				when "in" then Cmd::ControlFlow::IfIn
				when "contains" then Cmd::ControlFlow::IfContains
				when "not"
					case
					when arg2.starts_with?("between ")
						arg2 = arg2[8..]
						Cmd::ControlFlow::IfNotBetween
					when arg2.starts_with?("in ")
						arg2 = arg2[3..]
						Cmd::ControlFlow::IfNotIn
					when arg2.starts_with?("contains ")
						arg2 = arg2[9..]
						Cmd::ControlFlow::IfNotContains
					end
				end
				raise "If condition '#{operator}' is unknown" if ! cmd_class
				csv_args = [var_name, arg2]
				@cmds << cmd_class.new line_no, csv_args
			elsif line_content.includes?("::")
				add_line "Return", line_no if @hotstrings.empty? && @hotkey_definitions.empty?
				label, instant_action = line_content.split(/(?<=.)::/, limit: 2)
				if label.starts_with?(":") # Hotstring
					match = label.match(/^:([^:]*):([^:]+)$/)
					raise "Hotstring definition invalid or too complicated " if match.nil?
					_, options, abbrev = match
					@cmds << Cmd::ControlFlow::Label.new line_no, [label.downcase]
					hotstring = Run::Hotstring.new label, abbrev,
						options: @hotstring_default_options + options,
						escape_char: @runner_settings.escape_char
					@hotstrings << hotstring
					if ! instant_action.empty?
						end_char = hotstring.omit_ending_character ? "" : "%A_EndChar%"
						send = hotstring.auto_send_raw ? "SendRaw" : "Send"
						add_line "#{send}, #{instant_action}#{end_char}", line_no
						add_line "Return", line_no
					end
				else # Hotkey
					if ! instant_action.empty?
						instant_action_first_word = instant_action.split(/[\s,]/)[0].downcase
						if ! @@cmd_class_by_name[instant_action_first_word]?
							remap_key = instant_action_first_word
							label = "*" + label
						end
					end
					@cmds << Cmd::ControlFlow::Label.new line_no, [label.downcase]
					key_combo = Util::AhkString.parse_key_combinations(label.gsub("*","").gsub("~",""), @runner_settings.escape_char, implicit_braces: true)[0]?
					raise Run::RuntimeException.new "Hotkey '#{label}' not understood" if ! key_combo
					@hotkey_definitions << Run::HotkeyDefinition.new(label, key_combo: key_combo, priority: 0, max_threads: @runner_settings.max_threads_per_hotkey)
					if ! instant_action.empty?
						if remap_key
							add_line "Send, {blind}{#{remap_key} down}", line_no
							add_line "Return", line_no
							add_line "#{label} up::", line_no
							add_line "Send, {blind}{#{remap_key} up}", line_no
							add_line "Return", line_no
						else
							add_line "#{instant_action}", line_no
							add_line "Return", line_no
						end
					end
				end
			elsif first_word == "gui"
				# Gui accepts many subcommands. Instead of duplicating parsing logic into a generic
				# `Gui` cmd, instead join together (e.g. `GuiAdd`) and parse line again with that.
				# All subcommands exist as standalone commands and expect the gui id as 1st arg.
				# GUI, sub-command [, Param2, Param3, Param4]
				split = args.split(',', 2).map &.strip
				sub_instruction = split[0]? || ""
				rest_args = split[1]? || ""
				gui_id, sub_cmd = Parser.gui_sub_instruction_to_id_and_cmd(sub_instruction)
				raise "Gui subcommand missing" if sub_cmd.empty?
				if sub_cmd.starts_with?('-') || sub_cmd.starts_with?('+')
					rest_args = sub_cmd
					sub_cmd = "Option"
				end
				comma = rest_args.empty? ? "" : ","
				add_line "Gui#{sub_cmd}, #{gui_id}#{comma} #{rest_args}", line_no
				@runner_settings.persistent = true
			elsif first_word.ends_with?(':')
				@cmds << Cmd::ControlFlow::Label.new line_no, [first_word[...-1]]
			elsif first_word.ends_with?("++")
				@cmds << Cmd::Math::EnvAdd.new line_no, [first_word[...-2], "1"]
			elsif first_word.starts_with?("++")
				@cmds << Cmd::Math::EnvAdd.new line_no, [first_word[2..], "1"]
			elsif first_word.ends_with?("--")
				@cmds << Cmd::Math::EnvSub.new line_no, [first_word[...-2], "1"]
			elsif first_word.starts_with?("--")
				@cmds << Cmd::Math::EnvSub.new line_no, [first_word[2..], "1"]
			else
				split = args.split(2)
				second_word, other_arg = split[0]?, split[1]?
				csv_args = [first_word, other_arg || ""]
				case second_word
				when "="
					cmd_class = Cmd::Math::SetEnv
				when "+="
					cmd_class = Cmd::Math::EnvAdd
					raise "Add value missing for '+=' expression" if ! other_arg
				when "-="
					cmd_class = Cmd::Math::EnvSub
					raise "Sub value missing for '-=' expression" if ! other_arg
				when "*="
					cmd_class = Cmd::Math::EnvMult
					raise "Mult value missing for '*=' expression" if ! other_arg
				when "/="
					cmd_class = Cmd::Math::EnvDiv
					raise "Div value missing for '/=' expression" if ! other_arg
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

		def self.gui_sub_instruction_to_id_and_cmd(sub_instruction)
			match = sub_instruction.match(/(?:(\S+)\s*:\s*)?(.*)/).not_nil!
			gui_id = match[1]? || "1"
			sub_cmd = match[2]
			return gui_id, sub_cmd
		end
	end
end