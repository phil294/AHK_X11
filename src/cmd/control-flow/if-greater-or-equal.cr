require "./if-comparison"
class Cmd::ControlFlow::IfGreaterOrEqual < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a >= b
	end
end