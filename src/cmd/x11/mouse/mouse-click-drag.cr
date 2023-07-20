require "./mouse-click"

# MouseClickDrag, WhichButton, X1, Y1, X2, Y2 [, Speed, R]
class Cmd::X11::Mouse::MouseClickDrag < Cmd::X11::Mouse::MouseClick
	def self.min_args; 5 end
	def self.max_args; 7 end
	def run(thread, args)
		parse_run thread, [args[0], args[1], args[2], "1", args[5]? || "", "D", args[6]? || ""]
		parse_run thread, [args[0], args[3], args[4], "1", args[5]? || "", "U", args[6]? || ""]
	end
end