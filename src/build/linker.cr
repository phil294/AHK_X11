module Build
	# describes some kind of logic struct that can handle sub cmds with or without {},
	# such as `if` or `loop`. At minimum, an implementation needs to have one section
	# where these can be inserted into.
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
		@resolved = false

		abstract def initialize(conditional_cmd : Cmd::Base)
		
		# bottommost section, regardless if open or not
		private abstract def active_section : ConditionalSection
		
		def block_start
			raise "" if active_section.block_started || active_section.first_child
			active_section.block_started = true
		end
		def block_end
			raise "" if active_section.block_ended || ! active_section.block_started
			active_section.block_ended = true
		end
		def cmd(cmd : Cmd::Base)
			raise "" if ! active_section.open?
			active_section.first_child ||= cmd
			active_section.last_child = cmd
		end

		# does not need any more child cmds, good to resolve and destroy. Doesn't mean it immediately has to though
		def resolvable?
			! active_section.open?
		end
		# link all collected cmds appropriately to each other, with the final ones pointing to
		# *next_cmd* if given (if omitted, this will mean this conditional element is the end of the file)
		def resolve(next_cmd : Cmd::Base? = nil)
			raise "" if ! resolvable?
			return if @resolved
			link_children_to_cmd = link_all next_cmd
			while @child_conditionals.last?
				@child_conditionals.last.resolve link_children_to_cmd
				@child_conditionals.pop
			end
			@resolved = true
		end

		# return the cmd where child control flaws should redirect to at their end(s)
		private abstract def link_all(next_cmd : Cmd::Base? = nil) : Cmd::Base?
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
			@else_section = ConditionalSection.new Cmd::Else.new(0, [] of String)
		end
		
		private def link_all(next_cmd : Cmd::Base? = nil) : Cmd::Base?
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

	class LoopConditional < Conditional
		def initialize(conditional_cmd : Cmd::Base)
			@section = ConditionalSection.new conditional_cmd
		end
		private def active_section : ConditionalSection
			@section
		end

		@breaks = [] of Cmd::Break
		@continues = [] of Cmd::Continue
		def cmd(cmd : Cmd::Base)
			super(cmd)
			@breaks << cmd if cmd.is_a?(Cmd::Break)
			@continues << cmd if cmd.is_a?(Cmd::Continue)
		end
		private def link_all(next_cmd : Cmd::Base? = nil) : Cmd::Base?
			@section.cmd.je = @section.first_child || next_cmd
			@section.last_child.try &.next = @section.cmd
			@breaks.each &.next = next_cmd
			@continues.each &.next = @section.cmd
			@section.cmd.jne = next_cmd
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
			pending_labels = [] of String
			last_normal = nil
			conds = [] of Conditional
			is_else = false
			cmds.each do |cmd|
				is_normal = false
				begin
					if cmd.is_a?(Cmd::Label)
						pending_labels << cmd.name
						next
					end

					if cmd.is_a?(Cmd::Else)
						raise "" if is_else
						is_else = true
						next
					end

					# type guard apparently too complicated for type restriction, probably compiler limitation;
					# that's why there's some `.unsafe_as(IfConditional)` inside is_else blocks below
					raise "" if is_else && (!conds.last? || ! conds.last.is_a?(IfConditional))

					if cmd.is_a?(Cmd::BlockStart)
						raise "" if ! conds.last
						conds.last.unsafe_as(IfConditional).else if is_else
						conds.last.block_start
					elsif cmd.is_a?(Cmd::BlockEnd)
						while conds.last? && conds.last.resolvable?
							conds.pop
						end
						raise "" if ! conds.last? || is_else
						conds.last.block_end
					else # any command, including if or loop
						if is_else
							if cmd.class.conditional
								conds.last.unsafe_as(IfConditional).else_if cmd
							else
								conds.last.unsafe_as(IfConditional).else
								conds.last.cmd cmd
							end
						else
							is_normal = true
							last_normal.next = cmd if last_normal # only link two normal cmds to each other
							while conds.last? && conds.last.resolvable?
								conds.last.resolve cmd
								conds.pop
							end
							conds.last.cmd cmd if conds.last?
							if cmd.class.conditional
								if cmd.is_a?(Cmd::Loop)
									new_condition = LoopConditional.new cmd
								else
									new_condition = IfConditional.new cmd
								end
								conds.last.child_conditionals << new_condition if conds.last?
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