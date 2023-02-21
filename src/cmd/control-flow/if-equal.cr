require "./if-comparison"
# IfEqual, var, value (same: if var = value)
class Cmd::ControlFlow::IfEqual < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a == b
	end
end