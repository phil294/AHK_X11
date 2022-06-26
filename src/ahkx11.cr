require "./parser"

# test code
ahk_script = [
	"Echo some te,,,xt",
	" 	 filecopy a*,  aout ,  ",
]

parser = Parser.new

cmds = parser.parse_into_cmds ahk_script

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