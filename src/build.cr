require "./parser"

# describes some kind of logic struct that can handle sub cmds with or without {},
# such as `if` or `loop`. At minimum, an implementation needs to have one control flow section
# where these can be inserted into.
abstract class ControlFlow
	class ControlFlowSection
		property cmd : Cmd
		property first_child : Cmd?
		property last_child : Cmd?
		property block_started = false
		property block_ended = false
		def initialize(@cmd)
		end
		# still accepts child cmds? inside {} block or single line je that doesn't exist yet
		def open?
			@block_started && ! @block_ended || ! @block_started && ! @first_child
		end
	end

	getter child_control_flows = [] of ControlFlow
	@resolved = false

	abstract def initialize(control_flow_cmd : Cmd)
	
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
	def cmd(cmd : Cmd)
		raise "" if ! active_section.open?
		active_section.first_child ||= cmd
		active_section.last_child = cmd
	end

	# does not need any more child cmds, good to resolve and destroy. Doesn't mean it immediately has to though
	def resolvable?
		! active_section.open?
	end
	# link all collected cmds appropriately to each other, with the final ones pointing to
	# *next_cmd* if given (if omitted, this will mean this flow element is the end of the file)
	def resolve(next_cmd : Cmd? = nil)
		raise "" if ! resolvable?
		return if @resolved
		link_children_to_cmd = link_all next_cmd
		while @child_control_flows.last?
			@child_control_flows.last.resolve link_children_to_cmd
			@child_control_flows.pop
		end
		@resolved = true
	end

	# return the cmd where child control flaws should redirect to at their end(s)
	private abstract def link_all(next_cmd : Cmd? = nil) : Cmd?
end

class IfControlFlow < ControlFlow
	@if_section : ControlFlowSection
	@if_else_sections = [] of ControlFlowSection
	@else_section : ControlFlowSection?

	def initialize(control_flow_cmd : Cmd)
		@if_section = ControlFlowSection.new control_flow_cmd
	end

	private def active_section : ControlFlowSection
		@else_section || @if_else_sections.last? || @if_section
	end

	def else_if(if_cond : Cmd)
		raise "" if @else_section || active_section.open?
		@if_else_sections << ControlFlowSection.new if_cond
	end
	def else
		raise "" if @else_section || active_section.open?
		@else_section = ControlFlowSection.new ElseCmd.new(0, "")
	end
	
	private def link_all(next_cmd : Cmd? = nil) : Cmd?
		@if_section.cmd.je = @if_section.first_child || next_cmd
		@if_section.last_child.try &.next = next_cmd
		@if_section.cmd.jne = @if_else_sections.first?.try &.first_child || @else_section.try &.first_child || next_cmd
		@if_else_sections.each_with_index do | if_else_section, i |
			if_else_section.cmd.je = if_else_section.first_child || next_cmd
			if_else_section.last_child.try &.next = next_cmd
			if_else_section.cmd.jne = @if_else_sections[i+1]?.try &.first_child || @else_section.try &.first_child || next_cmd
		end
		@else_section.try &.last_child.try &.next = next_cmd
		next_cmd
	end
end

class LoopControlFlow < ControlFlow
	def initialize(control_flow_cmd : Cmd)
		@section = ControlFlowSection.new control_flow_cmd
	end
	private def active_section : ControlFlowSection
		@section
	end

	@breaks = [] of BreakCmd
	@continues = [] of ContinueCmd
	def cmd(cmd : Cmd)
		super(cmd)
		@breaks << cmd if cmd.is_a?(BreakCmd)
		@continues << cmd if cmd.is_a?(ContinueCmd)
	end
	private def link_all(next_cmd : Cmd? = nil) : Cmd?
		@section.cmd.je = @section.first_child || next_cmd
		@section.last_child.try &.next = @section.cmd
		@breaks.each &.next = next_cmd
		@continues.each &.next = @section.cmd
		@section.cmd.jne = next_cmd
		@section.cmd
	end
end

# parses and transforms ahk lines into a linked list of cmds that can be iterated without
# any further interlinking state. In other words, all if/else/loop "commands" are eaten up
# and replaced with direct cmd go tos.
class Builder
	@parser = Parser.new

	def build(lines : Array(String))
		cmds = @parser.parse_into_cmds lines
		to_cmd_chain cmds
	end

	def to_cmd_chain(cmds)
		start = nil
		last_normal = nil
		flows = [] of ControlFlow
		is_else = false
		cmds.each do |cmd|
			is_normal = false
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
					if is_else
						if cmd.class.control_flow
							flows.last.unsafe_as(IfControlFlow).else_if cmd
						else
							flows.last.unsafe_as(IfControlFlow).else
							flows.last.cmd cmd
						end
					else
						is_normal = true
						last_normal.next = cmd if last_normal # only link two normal cmds to each other
						while flows.last? && flows.last.resolvable?
							flows.last.resolve cmd
							flows.pop
						end
						flows.last.cmd cmd if flows.last?
						if cmd.class.control_flow
							if cmd.is_a?(LoopCmd)
								new_cond = LoopControlFlow.new cmd
							else
								new_cond = IfControlFlow.new cmd
							end
							flows.last.child_control_flows << new_cond if flows.last?
							flows << new_cond
						end
					end
				end

				if is_normal
					start ||= cmd
					last_normal = cmd
				else
					last_normal = nil
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

		# pp! cmds

		start
	end
end