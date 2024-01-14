# MouseClick, WhichButton [, X, Y, ClickCount, Speed, D|U, R]
class Cmd::X11::Mouse::MouseClick < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 7 end
	def run(thread, args)
		parse_run(thread, args)
	end
	protected def parse_run(thread, args)
		mouse_keysym = case args[0].downcase
		# todo: these mappings are the inverse of x11 ahk_key_name_to_keysym_custom, unify somehow? maybe even specific type?
		when "right", "r" then 3
		when "middle", "m" then 2
		when "wheelup", "wu" then 4
		when "wheeldown", "wd" then 5
		when "wheelleft", "wl" then 6
		when "wheelright", "wr" then 7
		when "xbutton1", "x1" then 8
		when "xbutton2", "x2" then 9
		else 1
		end
		x = args[1]?.try &.to_i?
		y = args[2]?.try &.to_i?
		if x && y
			if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
				x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x, y)
			end
		end
		relative = args[6]?.try &.downcase == "r"
		count = args[3]?.try &.to_i? || 1
		# For speed, see mouse-move.cr
		up = down = false
		case args[5]?.try &.downcase
		when "d" then down = true
		when "u" then up = true
		end
		thread.runner.display.pause do
			if x && y
				thread.runner.display.adapter.mouse_move thread, x, y, relative
				sleep thread.settings.mouse_delay.milliseconds if thread.settings.mouse_delay > -1
			end
			count.times do
				thread.runner.display.adapter.mouse_down mouse_keysym if ! up
				thread.runner.display.adapter.mouse_up mouse_keysym if ! down
				sleep thread.settings.mouse_delay.milliseconds if thread.settings.mouse_delay > -1
			end
		end
	end
end