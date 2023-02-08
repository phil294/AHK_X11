class Cmd::Misc::PixelSearch < Cmd::Base
	def self.min_args; 7 end
	def self.max_args; 9 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_x = args[0]
		out_y = args[1]
		x1 = args[2].to_i? || 0
		y1 = args[3].to_i? || 0
		x2 = args[4].to_i? || 0
		y2 = args[5].to_i? || 0
		if thread.settings.coord_mode_pixel == ::Run::CoordMode::RELATIVE
			x1, y1 = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x1, y1)
			x2, y2 = Cmd::X11::Window::Util.coord_relative_to_screen(thread, x2, y2)
		end
		search_color_s = args[6].to_i(prefix: true).to_s(16, precision: 6)
		# this should rather be done by bit shifting but I can't be bothered right now sorry
		search_color = StaticArray[ search_color_s[0..1].to_i(16), search_color_s[2..3].to_i(16), search_color_s[4..5].to_i(16) ]
		rgb = ((args[8]?.try &.downcase) || "") == "rgb"
		search_color.reverse! if ! rgb
		variation = args[7]?.try &.to_i? || 0
		w = x2 - x1 + 1
		h = y2 - y1 + 1
		thread.runner.display.gui.act do
			# https://docs.gtk.org/gdk-pixbuf/class.Pixbuf.html#image-data
			pixbuf = Gdk.pixbuf_get_from_window(Gdk.default_root_window, x1, y1, w, h)
			next "2" if ! pixbuf || pixbuf.bits_per_sample != 8 || pixbuf.colorspace != GdkPixbuf::Colorspace::Rgb || pixbuf.width != w || pixbuf.height != h || x1 < 0 || y1 < 0
			row_stride = pixbuf.rowstride
			n_channels = pixbuf.n_channels
			pixels = pixbuf.pixels
			is_match = false
			h.times do |y|
				w.times do |x|
					offset = y * row_stride + x * n_channels
					match =
						(pixels[offset].to_i - search_color[0]).abs <= variation &&
						(pixels[offset + 1].to_i - search_color[1]).abs <= variation &&
						(pixels[offset + 2].to_i - search_color[2]).abs <= variation
					if match
						match_x = x + x1
						match_y = y + y1
						if thread.settings.coord_mode_pixel == ::Run::CoordMode::RELATIVE
							match_y, match_x = Cmd::X11::Window::Util.coord_screen_to_relative(thread, match_y, match_x)
						end
						thread.runner.set_user_var(out_x, match_x.to_s) if ! out_x.empty?
						thread.runner.set_user_var(out_y, match_y.to_s) if ! out_y.empty?
						is_match = true
						break
					end
				end
				break if is_match
			end
			next is_match ? "0" : "1"
		end
	end
end