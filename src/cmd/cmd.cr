abstract class Cmd
	def self.name; "cmd"; end
	def self.min_args; 0 end
	# anything above max_args will not be split or stripped anymore, instead either combined
	# into the last arg (allowing for commands with open end like SetEnv or Echo) or moved
	# into a separate, new line, depending on the `multi_command` flag.
	def self.max_args; 0 end
	# :ditto:
	def self.multi_command; false end
	def self.control_flow; false end

	getter line_no = -1
	@args : Array(String)

	def initialize(@line_no, @args)
	end
	
	abstract def run(runner)

	property next : Cmd?
	property je : Cmd?
	property jne : Cmd?
	
	# TODO
	# def self.all_subclasses : Array(Cmd.class)
	# 	# {{ @type.all_subclasses.map &.class }}
	# 	[ EchoCmd ]
	# end

	def inspect
		"#{self.class.name}\n    @#{pointerof(@line_no)} line_no #{@line_no}\n    next: #{@next.class.name}\n    je: #{je.class.name}\n    jne: #{jne.class.name}"
	end

end

class SyntaxException < Exception end

class RuntimeException < Exception end