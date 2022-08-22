require "./if-comparison"
class Cmd::ControlFlow::IfNotEqual < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a != b
	end
end