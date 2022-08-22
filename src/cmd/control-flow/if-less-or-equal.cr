require "./if-comparison"
class Cmd::ControlFlow::IfLessOrEqual < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a <= b
	end
end