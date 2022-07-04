require "./norun"

class LabelCmd < Cmd
	include NoRun
	def self.name; "label"; end
	def self.min_args; 1 end
	def self.max_args; 1 end
	getter name : String
	def initialize(@line_no, args)
		@name = args[0]
	end
end