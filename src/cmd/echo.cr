require "./cmd"

# INCOMPAT: exists
class EchoCmd < Cmd
	@body : String
	def initialize(args)
		@body = args.join(", ")
	end
	def run
		puts @body
	end
end