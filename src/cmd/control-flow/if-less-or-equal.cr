require "./if-comparison"
# IfLessOrEqual, var, value (same: if var <= value)
class Cmd::ControlFlow::IfLessOrEqual < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a <= b
	end
end