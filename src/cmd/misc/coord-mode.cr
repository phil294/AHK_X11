# CoordMode, ToolTip|Pixel|Mouse [, Screen|Relative]
class Cmd::Misc::CoordMode < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread, args)
		mode = ((args[1]?.try &.downcase) || "") == "relative" ?
			::Run::CoordMode::RELATIVE :
			::Run::CoordMode::SCREEN
		case args[0].downcase
		when "tooltip"
			thread.settings.coord_mode_tooltip = mode
		when "pixel"
			thread.settings.coord_mode_pixel = mode
		when "mouse"
			thread.settings.coord_mode_mouse = mode
		when "caret"
			thread.settings.coord_mode_caret = mode
		when "menu"
			thread.settings.coord_mode_menu = mode
		end
	end
end