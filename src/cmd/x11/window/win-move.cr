require "./win-util"
# WinMove, WinTitle, WinText, X, Y [, Width, Height, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinMove < Cmd::Base
	def self.min_args; 4 end
	def self.max_args; 8 end
	def run(thread, args)
		x = args[2].to_i? || 0
		y = args[3].to_i? || 0
		w = args[4]?.try &.to_i?
		h = args[5]?.try &.to_i?
		args.delete_at(2)
		args.delete_at(2)
		args.delete_at(2) if args[2]?
		args.delete_at(2) if args[2]?
		Util.match_win(thread, args) do |win|
			win.move x, y
			win.resize w, h if w && h
		end
	end
end