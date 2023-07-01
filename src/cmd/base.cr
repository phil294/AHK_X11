module Cmd
	abstract class Base
		# For example, for `Cmd::File::FileCopy` it's `"filecopy"`
		def self.name
			{{ @type.name(generic_args: false).stringify.downcase.split("::").last }}
		end
		def self.min_args; 0 end
		# anything above max_args will not be split or stripped anymore, instead either combined
		# into the last arg (allowing for commands with open end like SetEnv or Echo) or moved
		# into a separate, new line, depending on the `multi_command` flag.
		def self.max_args; 0 end
		# :ditto:
		def self.multi_command; false end
		# conditional commands require special treatment and implementation in `Build::Linker`
		def self.conditional; false end
		# see `run`
		def self.sets_error_level; false end

		getter line_no = -1
		getter args : Array(::String)

		def initialize(@line_no, @args)
		end
		
		# *args* is like `@args`, but parsed (vars substituted).
		# runner can be accessed via `thread.runner`.
		# When `class.conditional`, the return value determines the next branch.
		# When `class.sets_error_level`, the thread's `ErrorLevel` will be set
		# to the return value.
		# In all other cases, the return value is ignored.
		abstract def run(thread, args)

		property next : Base?
		property je : Base?
		property jne : Base?
		
		def self.all_subclasses
			{{ @type.all_subclasses }}
		end

		# TODO: why doesn't this work?? p! @hotkeys[0] prints all properties of the cmd chain including @args and so on even though we override it here
		def inspect
			"#{self.class.name}, @#{pointerof(@line_no)} line_no #{@line_no}, next: #{@next.class.name}, je: #{je.class.name}, jne: #{jne.class.name}"
		end
		def to_s(io)
			io << inspect
		end
	end
end