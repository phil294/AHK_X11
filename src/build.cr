require "./parser"

class Instruction # maybe combine this and Cmd into single class
	getter cmd : Cmd
	def initialize(@cmd)
	end
	def conditional
		@cmd.class.conditional
	end
	property next : Instruction?
	property je : Instruction?
	property jne : Instruction?
end

class Conditional
	class ConditionalSection
		property instruction : Instruction
		property first_child : Instruction?
		property last_child : Instruction?
		property block_started = false
		property block_ended = false
		def initialize(@instruction)
		end
		# still accepts child instructions? inside {} block or single line je that doesn't exist yet
		def open?
			@block_started && ! @block_ended || ! @block_started && ! @first_child
		end
	end

	@if_section : ConditionalSection
	@if_else_sections = [] of ConditionalSection
	@else_section : ConditionalSection?
	getter child_conditionals = [] of Conditional

	def initialize(conditional_ins : Instruction)
		@if_section = ConditionalSection.new conditional_ins
	end
	# bottommost section, regardless if open or not
	private def last_section
		@else_section || @if_else_sections.last? || @if_section
	end
	def else_if(if_cond : Instruction)
		raise "" if @else_section || last_section.open?
		@if_else_sections << ConditionalSection.new if_cond
	end
	def else
		raise "" if @else_section || last_section.open?
		@else_section = ConditionalSection.new Instruction.new(ElseCmd.new(0, ""))
	end
	def block_start
		raise "" if last_section.block_started || last_section.first_child
		last_section.block_started = true
	end
	def block_end
		raise "" if last_section.block_ended || ! last_section.block_started
		last_section.block_ended = true
	end
	def ins(ins : Instruction)
		raise "" if ! last_section.open?
		last_section.first_child ||= ins
		last_section.last_child = ins
	end
	# does not need any more child instructions, good to resolve and destroy. Doesn't mean it has to though,
	# there can be any amount of else-ifs added before the last else
	def resolvable?
		! last_section.open?
	end
	# link all collected instructions appropriately to each other, with the final ones pointing to
	# *next_ins* if given (if omitted, this will mean this `if` is the end of the ahkthread / followed by return)
	def resolve(next_ins : Instruction? = nil)
		raise "" if ! resolvable?
		@child_conditionals.each &.resolve # recursive; order doesn't matter
		@if_section.instruction.je = @if_section.first_child || next_ins
		@if_section.last_child.try &.next = next_ins
		@if_section.instruction.jne = @if_else_sections.first?.try &.first_child || @else_section.try &.first_child || next_ins
		@if_else_sections.each_with_index do | if_else_section, i |
			if_else_section.instruction.je = if_else_section.first_child || next_ins
			if_else_section.last_child.try &.next = next_ins
			if_else_section.instruction.jne = @if_else_sections[i+1]?.try &.first_child || @else_section.try &.first_child || next_ins
		end
		@else_section.try &.last_child.try &.next = next_ins
	end
end

# parses and transforms ahk lines into a linked list of instructions that can be iterated without
# any further interlinking state. In other words, all if/else/loop "commands" are eaten up
# and replaced with direct instruction go tos.
class Builder
	@parser = Parser.new

	def build(lines : Array(String))
		cmds = @parser.parse_into_cmds lines
		to_instruction_chain cmds
	end

	def to_instruction_chain(cmds)
		start = nil
		last = nil
		conds = [] of Conditional
		is_else = false
		cmds.each do |cmd|
			begin
				if cmd.is_a?(ElseCmd)
					raise "" if is_else
					is_else = true
					next
				end

				if cmd.is_a?(BlockStartCmd)
					raise "" if ! conds.last
					conds.last.else if is_else
					conds.last.block_start
				elsif cmd.is_a?(BlockEndCmd)
					while conds.last? && conds.last.resolvable?
						conds.pop
					end
					raise "" if ! conds.last? || is_else
					conds.last.block_end
				else # any command, including if or loop
					ins = Instruction.new cmd
					last.next = ins if last
					last = ins
					start ||= ins
					if is_else
						raise "" if ! conds.last?
						if ins.conditional
							conds.last.else_if ins
						else
							conds.last.else
							conds.last.ins ins
						end
					else
						while conds.last? && conds.last.resolvable?
							conds.last.resolve ins
							conds.pop
						end
						conds.last.ins ins if conds.last?
						if ins.conditional
							new_cond = Conditional.new ins
							conds.last.child_conditionals << new_cond if conds.last?
							conds << new_cond
						end
					end
				end

				is_else = false
			rescue e
				raise SyntaxException.new "Unexpected '#{cmd.class.name}' in line #{cmd.line_no+1}. #{e.message}"
			end
		end

		while conds.last?
			begin
				conds.last.resolve
			rescue e
				raise SyntaxException.new "Could not parse condition near the end of the script; most likely a closing brace is missing somewhere. (#{e.message})"
			end
			conds.pop
		end

		start
	end
end