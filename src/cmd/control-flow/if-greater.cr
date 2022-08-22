require "./if-comparison"
class Cmd::ControlFlow::IfGreater < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a > b
	end
end