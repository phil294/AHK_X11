module Build
	# include Cmd
	include Cmd::ControlFlow

	# describes some kind of logic struct that can handle sub cmds with or without {},
	# such as `if` or `loop`. At minimum, an implementation needs to have one section
	# where these can be inserted into.
	# An instance of this is only used for the linking process and can be disregarded after that.
	abstract class Conditional
		class ConditionalSection
			property cmd : Cmd::Base
			property first_child : Cmd::Base?
			property last_child : Cmd::Base?
			property block_started = false
			property block_ended = false
			def initialize(@cmd)
			end
			# still accepts child cmds? inside {} block or single line je that doesn't exist yet
			def open?
				@block_started && ! @block_ended || ! @block_started && ! @first_child
			end
		end

		getter child_conditionals = [] of Conditional
		property parent_conditional : Conditional? = nil
		@resolved = false

		abstract def initialize(conditional_cmd : Cmd::Base)
		
		# bottommost section, regardless if open or not
		private abstract def active_section : ConditionalSection
		
		def start_block
			raise "" if active_section.block_started || active_section.first_child
			active_section.block_started = true
		end
		def end_block
			raise "" if active_section.block_ended || ! active_section.block_started
			active_section.block_ended = true
		end
		def add_cmd(cmd : Cmd::Base)
			raise "" if ! active_section.open?
			active_section.first_child ||= cmd
			active_section.last_child = cmd
			self.break cmd if cmd.is_a?(Break)
			self.continue cmd if cmd.is_a?(Continue)
		end
		def break(cmd : Break)
			raise "" if ! @parent_conditional
			@parent_conditional.not_nil!.break cmd
		end
		def continue(cmd : Continue)
			raise "" if ! @parent_conditional
			@parent_conditional.not_nil!.continue cmd
		end

		# does not need any more child cmds, good to resolve and destroy. Doesn't mean it immediately has to though
		def resolvable?
			! active_section.open?
		end
		# link all collected cmds appropriately to each other, with the final ones pointing to
		# *next_cmd_outside* if given (if omitted, this will mean this conditional element is the end of the file)
		def resolve(next_cmd_outside : Cmd::Base? = nil)
			raise "" if ! resolvable?
			return if @resolved
			while @child_conditionals.last?
				@child_conditionals.last.resolve next_cmd_at_end(next_cmd_outside)
				@child_conditionals.pop
			end
			link_all next_cmd_outside
			@resolved = true
		end

		private abstract def link_all(next_cmd_outside : Cmd::Base? = nil)

		# return the cmd where commands should go to next at the very bottom of this conditional.
		# If they are expected to just jump out and continue, return *next_cmd_outside* itself.
		private abstract def next_cmd_at_end(next_cmd_outside : Cmd::Base? = nil) : Cmd::Base?
	end

	class IfConditional < Conditional
		@if_section : ConditionalSection
		@if_else_sections = [] of ConditionalSection
		@else_section : ConditionalSection?

		def initialize(conditional_cmd : Cmd::Base)
			@if_section = ConditionalSection.new conditional_cmd
		end

		private def active_section : ConditionalSection
			@else_section || @if_else_sections.last? || @if_section
		end

		def else_if(if_condition : Cmd::Base)
			raise "" if @else_section || active_section.open?
			@if_else_sections << ConditionalSection.new if_condition
		end
		def else
			raise "" if @else_section || active_section.open?
			@else_section = ConditionalSection.new Else.new(0, [] of String)
		end
		
		private def link_all(next_cmd_outside : Cmd::Base? = nil)
			@if_section.cmd.je = @if_section.first_child || next_cmd_outside
			@if_section.last_child.try &.next = next_cmd_outside
			@if_section.cmd.jne = @if_else_sections.first?.try &.cmd || @else_section.try &.first_child || next_cmd_outside
			@if_else_sections.each_with_index do |if_else_section, i|
				if_else_section.cmd.je = if_else_section.first_child || next_cmd_outside
				if_else_section.last_child.try &.next = next_cmd_outside
				if_else_section.cmd.jne = @if_else_sections[i+1]?.try &.cmd || @else_section.try &.first_child || next_cmd_outside
			end
			@else_section.try &.last_child.try &.next = next_cmd_outside
		end
		private def next_cmd_at_end(next_cmd_outside : Cmd::Base? = nil) : Cmd::Base?
			next_cmd_outside
		end
	end

	class LoopConditional < Conditional
		def initialize(conditional_cmd : Cmd::Base)
			@section = ConditionalSection.new conditional_cmd
		end
		private def active_section : ConditionalSection
			@section
		end

		@breaks = [] of Break
		@continues = [] of Continue
		def break(cmd : Break)
			@breaks << cmd
			pp! "break loop"
		end
		def continue(cmd : Continue)
			@continues << cmd
		end
		private def link_all(next_cmd_outside : Cmd::Base? = nil)
			@section.cmd.je = @section.first_child || next_cmd_outside
			@section.last_child.try &.next = next_cmd_at_end
			@breaks.each &.next = next_cmd_outside
			@continues.each &.next = next_cmd_at_end
			@section.cmd.jne = next_cmd_outside
		end
		private def next_cmd_at_end(next_cmd_outside : Cmd::Base? = nil) : Cmd::Base?
			# Go top start of loop again
			@section.cmd
		end
	end

	# parses and transforms ahk lines into a linked list of cmds that can be iterated without
	# any further interlinking state. In other words, all if/else/loop commands are eaten up
	# and replaced with direct cmd go tos.
	class Linker
		getter start : Cmd::Base? = nil
		getter labels = {} of String => Cmd::Base

		def link!(cmds)
			@start = nil
			pending_labels = [] of String
			last_normal = nil
			conds = [] of Conditional
			is_else = false
			cmds.each do |cmd|
				is_normal = false
				begin
					case cmd
					when Label
						pending_labels << cmd.name
						next
					when Else
						raise "" if is_else
						is_else = true
						next
					end

					# type guard apparently too complicated for type restriction, probably compiler limitation;
					# that's why there's some `.unsafe_as(IfConditional)` inside is_else blocks below
					raise "" if is_else && (!conds.last? || ! conds.last.is_a?(IfConditional))

					case cmd
					when BlockStart
						raise "" if ! conds.last
						conds.last.unsafe_as(IfConditional).else if is_else
						conds.last.start_block
					when BlockEnd
						while conds.last? && conds.last.resolvable?
							conds.pop
						end
						raise "" if ! conds.last? || is_else
						conds.last.end_block
					when # any command, including if or loop
						if is_else
							if cmd.class.conditional
								conds.last.unsafe_as(IfConditional).else_if cmd
							else
								conds.last.unsafe_as(IfConditional).else
								conds.last.add_cmd cmd
							end
						else
							is_normal = true
							last_normal.next = cmd if last_normal # only link two normal cmds to each other
							while conds.last? && conds.last.resolvable?
								# e.g. the last commands were a loop, and now a new command comes along.
								# We resolve the loop and pass the current `cmd`, because any finish or `break`
								# inside the loop needs to point to it.
								conds.last.resolve cmd
								conds.pop
							end
							conds.last.add_cmd cmd if conds.last?
							if cmd.class.conditional
								if cmd.is_a?(Loop)
									new_condition = LoopConditional.new cmd
								else
									new_condition = IfConditional.new cmd
								end
								if conds.last?
									conds.last.child_conditionals << new_condition
									new_condition.parent_conditional = conds.last
								end
								conds << new_condition
							end
						end
					end

					if is_normal
						@start ||= cmd
						last_normal = cmd
						pending_labels.each { |lbl| labels[lbl] = cmd }
						pending_labels.clear
					else
						last_normal = nil
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

			# pp! cmds
		end
	end
end