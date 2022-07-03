require "./parser"

class Instruction # maybe combine this and Cmd into single class
	getter cmd : Cmd
	def initialize(@cmd)
	end
	def control_flow
		@cmd.class.control_flow
	end
	property next : Instruction?
	property je : Instruction?
	property jne : Instruction?
end

# describes some kind of logic struct that can handle sub instructions with or without {},
# such as `if` or `loop`. At minimum, an implementation needs to have one control flow section
# where these can be inserted into.
abstract class ControlFlow
	class ControlFlowSection
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

	getter child_control_flows = [] of ControlFlow
	@resolved = false

	abstract def initialize(control_flow_ins : Instruction)
	
	# bottommost section, regardless if open or not
	private abstract def active_section : ControlFlowSection
	
	def block_start
		raise "" if active_section.block_started || active_section.first_child
		active_section.block_started = true
	end
	def block_end
		raise "" if active_section.block_ended || ! active_section.block_started
		active_section.block_ended = true
	end
	def ins(ins : Instruction)
		raise "" if ! active_section.open?
		active_section.first_child ||= ins
		active_section.last_child = ins
	end

	# does not need any more child instructions, good to resolve and destroy. Doesn't mean it immediately has to though
	def resolvable?
		! active_section.open?
	end
	# link all collected instructions appropriately to each other, with the final ones pointing to
	# *next_ins* if given (if omitted, this will mean this flow element is the end of the file)
	def resolve(next_ins : Instruction? = nil)
		raise "" if ! resolvable?
		return if @resolved
		link_children_to_ins = link_all next_ins
		while @child_control_flows.last?
			@child_control_flows.last.resolve link_children_to_ins
			@child_control_flows.pop
		end
		@resolved = true
	end

	# return the instruction where child control flaws should redirect to at their end(s)
	private abstract def link_all(next_ins : Instruction? = nil) : Instruction?
end

class IfControlFlow < ControlFlow
	@if_section : ControlFlowSection
	@if_else_sections = [] of ControlFlowSection
	@else_section : ControlFlowSection?

	def initialize(control_flow_ins : Instruction)
		@if_section = ControlFlowSection.new control_flow_ins
	end

	private def active_section : ControlFlowSection
		@else_section || @if_else_sections.last? || @if_section
	end

	def else_if(if_cond : Instruction)
		raise "" if @else_section || active_section.open?
		@if_else_sections << ControlFlowSection.new if_cond
	end
	def else
		raise "" if @else_section || active_section.open?
		@else_section = ControlFlowSection.new Instruction.new(ElseCmd.new(0, ""))
	end
	
	private def link_all(next_ins : Instruction? = nil) : Instruction?
		@if_section.instruction.je = @if_section.first_child || next_ins
		@if_section.last_child.try &.next = next_ins
		@if_section.instruction.jne = @if_else_sections.first?.try &.first_child || @else_section.try &.first_child || next_ins
		@if_else_sections.each_with_index do | if_else_section, i |
			if_else_section.instruction.je = if_else_section.first_child || next_ins
			if_else_section.last_child.try &.next = next_ins
			if_else_section.instruction.jne = @if_else_sections[i+1]?.try &.first_child || @else_section.try &.first_child || next_ins
		end
		@else_section.try &.last_child.try &.next = next_ins
		next_ins
	end
end

class LoopControlFlow < ControlFlow
	def initialize(control_flow_ins : Instruction)
		@section = ControlFlowSection.new control_flow_ins
	end
	private def active_section : ControlFlowSection
		@section
	end

	private def link_all(next_ins : Instruction? = nil) : Instruction?
		@section.instruction.je = @section.first_child || next_ins
		@section.last_child.try &.next = @section.instruction
		@section.instruction.jne = next_ins
		@section.instruction
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
		flows = [] of ControlFlow
		is_else = false
		cmds.each do |cmd|
			begin
				if cmd.is_a?(ElseCmd)
					raise "" if is_else
					is_else = true
					next
				end

				# type guard apparently too complicated for type restriction, pbly compiler limitation;
				# that's why there's some `.unsafe_as(IfControlFlow)` inside is_else blocks below
				raise "" if is_else && (!flows.last? || ! flows.last.is_a?(IfControlFlow))

				if cmd.is_a?(BlockStartCmd)
					raise "" if ! flows.last
					flows.last.unsafe_as(IfControlFlow).else if is_else
					flows.last.block_start
				elsif cmd.is_a?(BlockEndCmd)
					while flows.last? && flows.last.resolvable?
						flows.pop
					end
					raise "" if ! flows.last? || is_else
					flows.last.block_end
				else # any command, including if or loop
					ins = Instruction.new cmd
					last.next = ins if last
					last = ins
					start ||= ins
					if is_else
						if ins.control_flow
							flows.last.unsafe_as(IfControlFlow).else_if ins
						else
							flows.last.unsafe_as(IfControlFlow).else
							flows.last.ins ins
						end
					else
						while flows.last? && flows.last.resolvable?
							flows.last.resolve ins
							flows.pop
						end
						flows.last.ins ins if flows.last?
						if ins.control_flow
							if cmd.is_a?(LoopCmd)
								new_cond = LoopControlFlow.new ins
							else
								new_cond = IfControlFlow.new ins
							end
							flows.last.child_control_flows << new_cond if flows.last?
							flows << new_cond
						end
					end
				end

				is_else = false
			rescue e
				raise SyntaxException.new "Unexpected '#{cmd.class.name}' in line #{cmd.line_no+1}. #{e.message}"
			end
		end

		while flows.last?
			begin
				flows.last.resolve
			rescue e
				raise SyntaxException.new "Could not parse condition near the end of the script; most likely a closing brace is missing somewhere. (#{e.message})"
			end
			flows.pop
		end

		start
	end
end