require "./if-comparison"
# IfNotEqual, var, value (same: if var <> value) (same: if var != value)
class Cmd::ControlFlow::IfNotEqual < Cmd::ControlFlow::IfComparison
	def compare(a, b)
		a != b
	end
end