require "./if-comparison"
class Cmd::ControlFlow::IfEqual < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a == b
	end
end