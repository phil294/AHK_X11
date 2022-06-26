abstract class Cmd
	# abstract def self.name
	abstract def initialize(args)
	abstract def run
end

class SyntaxException < Exception end

# INCOMPAT: file mod date is not preserved (seems better this way tho), glob is case sensitive
class FileCopyCmd < Cmd
	@srcs : String
	@dst : String
	@flag : UInt8
	def initialize(args)
		if args.size < 2
			raise SyntaxException.new("Too few arguments")
		end
		@srcs = args[0]
		@dst = args[1]
		@flag = (args[2]?.try &.to_u8) || 0_u8
	end
	def run
		Dir.glob(@srcs).each do |src|
			dst = ! Dir.exists?(@dst) ? @dst :
				Path[@dst, File.basename(src)]
			next if Dir.exists?(src) || Dir.exists?(dst)
			if File.exists? dst
				next if @flag == 0_u8
				File.delete dst
			end
			File.copy(src, dst)
		end
	end
end

# INCOMPAT: exists
class EchoCmd < Cmd
	@body : String
	def initialize(args)
		@body = args.join(", ")
	end
	def run
		puts @body
	end
end

class ParsingException < Exception end

class Parser
	@cmd_class_by_name = { # TODO solve with macro
		"filecopy" => FileCopyCmd,
		"echo" => EchoCmd,
	} of String => Cmd.class

	def build_instructions(lines : Array(String))
		cmds = [] of Cmd
		lines.each_with_index do |line, line_no|
			cmd_name = "" # todo should be nil instead pbly
			arg_start = 0
			arg_end = 0
			csv_args = [] of String
			line.each_char_with_index do |char, i|
				if cmd_name.empty?
					if ! char.ascii_letter?
						if (char.whitespace? || char == ',')
							if i > 0 # todo same as next line
								cmd_name = line[0..i-1].downcase.strip # todo this strip stuff makes cmd_name stay emtpy if only indention so far. this was just a quick hack and needs a rewrite
							end
						else
							raise ParsingException.new "Parsing Error in line #{line_no}"
						end
					end
				elsif char == ','
					csv_args << line[arg_start..arg_end]
					arg_start = 0
					arg_end = 0
				elsif ! char.whitespace? # trim leading and trailing spaces of all args
					arg_start = i if arg_start == 0
					arg_end = i
				end
			end
			if cmd_name.empty?
				cmd_name = line.strip.downcase
			elsif arg_start > 0
				csv_args << line[arg_start..arg_end]
			end
			
			cmd_class = @cmd_class_by_name[cmd_name]?
			if cmd_class.nil?
				raise ParsingException.new "Parsing Error in line #{line_no}"
			end
			begin
				cmd = cmd_class.new csv_args
			rescue e : SyntaxException
				raise SyntaxException.new "Syntax Error in line #{line_no} for command '#{cmd_name}': #{e.message}"
			end
			cmds << cmd
		end
		cmds
	end
end

# test code
ahk_script = [
	" 	 filecopy a*,  aout ,  ",
	"Echo some te,,,xt",
]

cmds = Parser.new.build_instructions ahk_script

class Instruction
	property je : Instruction? # not yet in use
	property jne : Instruction? # not yet in use
	getter cmd
	def initialize(@cmd : Cmd)
	end
end

start_instruction = nil
cmds.each do |cmd|
	instruction = Instruction.new cmd
	start_instruction ||= instruction
end

raise "????" if start_instruction.nil?

# so far only the first line executes
start_instruction.cmd.run