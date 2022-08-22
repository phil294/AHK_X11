require "./if-comparison"
class Cmd::ControlFlow::IfLess < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a < b
	end
end