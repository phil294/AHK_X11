require "../no-run"

class Cmd::ControlFlow::Label < Cmd::Base
	include NoRun
	def self.min_args; 1 end
	def self.max_args; 1 end
	getter name : String
	def initialize(@line_no, args)
		@name = args[0]
	end
end