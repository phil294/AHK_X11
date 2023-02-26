require "./if-comparison"
# IfGreater, var, value (same: if var > value)
class Cmd::ControlFlow::IfGreater < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a > b
	end
end