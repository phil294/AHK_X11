# MouseGetPos, [OutputVarX, OutputVarY, OutputVarWin, OutputVarControl]
class Cmd::X11::Mouse::MouseGetPos < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		x, y = thread.runner.display.adapter.mouse_pos
		if args[3]? && ! args[3].empty?
			_, _, _, window = thread.runner.display.x_do.mouse_location
			class_NN = thread.runner.display.at_spi do |at_spi|
				tl_acc = at_spi.find_top_level_accessible(thread, [window])
				if tl_acc
					result = thread.runner.display.at_spi &.find_descendant_of_top_level_accessible(thread, tl_acc, x: x.to_i32, y: y.to_i32)
					# TODO test
					next result && result[1]
				end
			end
			thread.runner.set_user_var(args[3], class_NN || "")
		end
		# todo: how to work with relative coords in wayland? do absolutes even work with atspi stuff?
		if thread.settings.coord_mode_mouse == ::Run::CoordMode::RELATIVE
			x, y = Cmd::X11::Window::Util.coord_screen_to_relative(thread, x, y)
		end
		thread.runner.set_user_var(args[0], x.to_s) if args[0]? && ! args[0].empty?
		thread.runner.set_user_var(args[1], y.to_s) if args[1]? && ! args[1].empty?
		if args[2]? && ! args[2].empty?
			_, _, _, window = thread.runner.display.x_do.mouse_location
			thread.runner.set_user_var(args[2], window.window.to_s)
		end
	end
end