require "./parser"

class Instruction # maybe combine this and Cmd into single class
	property je : Instruction?
	property jne : Instruction?
	property next : Instruction?
	property has_block = false
	getter cmd
	def initialize(@cmd : Cmd)
	end
end

class Builder
	@parser = Parser.new

	def build(lines : Array(String))
		cmds = @parser.parse_into_cmds lines
		to_instruction_chain cmds
	end

	def to_instruction_chain(cmds)
		start = nil
		last = nil
		conds = [] of Instruction
		cmds.each do |cmd|
			ins = Instruction.new cmd
			if conds.last?
				if ! conds.last.je
					conds.last.je = ins
				elsif ! conds.last.has_block && ! conds.last.jne
					conds.last.jne = ins
					conds.pop
				end
			end
			last.next = ins if last
			start ||= ins
			conds << ins if ins.cmd.conditional
			last = ins
		end

		start
	end
end