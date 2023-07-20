# MouseMove, X, Y [, Speed, R]
class Cmd::X11::Mouse::MouseMove < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		x_current, y_current, screen = thread.runner.display.x_do.mouse_location
		x = args[0]?.try &.to_i? || x_current
		y = args[1]?.try &.to_i? || y_current
		# Regarding speed: In Win AHK, speed is realized by moving the mouse step-wise,
		# with each step being 32px in w/h at least (but also somehow it works differently?!)
		# https://github.com/AutoHotkey/AutoHotkey/blob/e18a857e2d6d57d73643fbdd57d739a88ea499e5/source/keyboard_mouse.cpp#L2330
		# https://github.com/AutoHotkey/AutoHotkey/blob/c1f20dc8846ccad4dc54d3a1e69f39449c6ea1dc/source/script_autoit.cpp#L1828-L1888
		# For Linux, libxdo doesn't offer steps yet:
		# https://github.com/jordansissel/xdotool/blob/98a33e4ed1ae3753bcb20924dd6cdfa563331079/cmd_mousemove.c#L208
		# We can't take simulate the steps in Crystal code here because that would be too slow
		# (every xdo request takes ~30ms itself already). So a PR to xdotool implementing steps
		# would be necessary.
		relative = args[3]?.try &.downcase == "r"
		thread.runner.display.pause do
			if relative
				thread.runner.display.x_do.move_mouse x, y
			else
				if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
					x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x, y)
				end
				thread.runner.display.x_do.move_mouse x, y, screen
			end
		end
		sleep thread.settings.mouse_delay.milliseconds if thread.settings.mouse_delay > -1
	end
end