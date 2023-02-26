require "./if-comparison"
# IfLess, var, value (same: if var < value)
class Cmd::ControlFlow::IfLess < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a < b
	end
end