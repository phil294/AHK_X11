# PixelGetColor, OutputVar, X, Y [, RGB]
class Cmd::Misc::PixelGetColor < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 4 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var = args[0]
		x = args[1].to_i? || 0
		y = args[2].to_i? || 0
		if thread.settings.coord_mode_pixel == ::Run::CoordMode::RELATIVE
			x, y = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x, y)
		end
		rgb = ((args[3]?.try &.downcase) || "") == "rgb"
		thread.runner.display.gui.act do
			pixbuf = Gdk.pixbuf_get_from_window(Gdk.default_root_window, x, y, 1, 1)
			if pixbuf
				color = [] of UInt8
				# internal pixels storage is complex https://docs.gtk.org/gdk-pixbuf/class.Pixbuf.html#image-data
				# but here we just need the first three bytes
				pixbuf.pixels[0].each_slice(3) do |slice|
					color = slice
					break
				end
				color = color.reverse if ! rgb
				color_s = color.map { |c| c.to_s(16, upcase:true, precision:2) }.join
				thread.runner.set_user_var(out_var, color_s)
				next "0"
			end
			"1"
		end
	end
end