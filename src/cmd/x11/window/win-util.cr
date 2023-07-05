class Cmd::X11::Window::Util
	# Find a single window.
	# param `match_conditions` is those four `[, WinTitle, WinText, ExcludeTitle, ExcludeText]`
	# from the docs that are used in various window commands,
	# and can consequently also be an empty array.
	def self.match(thread, match_conditions, *, empty_is_last_found, a_is_active)
		title = match_conditions[0]? || ""
		if match_conditions.size == 0 || match_conditions.all? &.empty?
			raise Run::RuntimeException.new "expected window matching arguments as 'last found window' cannot be inferred here" if ! empty_is_last_found
			win = thread.settings.last_found_window
		elsif title.downcase == "a"
			raise Run::RuntimeException.new "expected window matching arguents as 'A' for active window cannot be inferred here" if ! a_is_active
			win = thread.runner.display.x_do.active_window
		else
			if title.starts_with?("ahk_id ")
				wid = title[7..].to_u64?
				raise Run::RuntimeException.new "ahk_id must be a number" if ! wid
				win = XDo::Window.new(thread.runner.display.x_do.xdo_p, wid)
    			win = nil if ! win.name # avoids segfaults
			else
				text = match_conditions[1]? || ""
				exclude_title = match_conditions[2]? || ""
				exclude_text = match_conditions[3]? || ""
				current_desktop = thread.runner.display.x_do.desktop.to_i32

				# Note: This can crash with "XGetWindowProperty failed!Invalid memory access (signal 11) at address 0x0 [...] xdo_get_desktop_for_window +120 in /usr/lib/libxdo
				# Which is fixed with an xdotool fork (see build/README.md)
				wins = thread.runner.display.x_do.search do
					require_all
					if ! thread.settings.detect_hidden_windows
						only_visible # if not present, this can seem unpredictable and buggy to the user https://github.com/jordansissel/xdotool/issues/67#issuecomment-1193573254
						# ^ link also explains the need for specifying desktop:
						desktop current_desktop
					end
					if title.starts_with?("ahk_class ")
						# TODO: these/name etc should all be case sensitive. Maybe double filter below? How performant is querying for .name etc?
						window_class_name title[10..] # TODO: is this regex? how to make partial matches like ahk?
					else
						window_name title # todo same as above / seems to be partial match but only at *start* of string
					end
				end.reject &.name.nil?

				wins.select! do |win|
					if ! exclude_title.empty?
						return false if win.name.not_nil!.includes? exclude_title 
					end
					if ! text.empty? || ! exclude_text.empty?
						win_texts = thread.runner.display.at_spi &.get_all_texts(thread, win, include_hidden: false)
						return false if ! win_texts
						if ! text.empty?
							return false if win_texts.empty? || ! win_texts.index &.includes?(text)
						end
						if ! exclude_text.empty?
							return false if win_texts.index &.includes?(exclude_text)
						end
					end
					true
				end
				win = wins.first?
			end
		end
		if win
			yield win
			# Somehow, most (all?) window manager commands like close! or minimize!
			# fail unless there is some other, arbitrary x11 request being sent after...
			# no idea why, also independent of libxdo version. This call works around it.
			thread.runner.display.x_do.focused_window sane: false
		end
		!!win
	end
	def self.coord_relative_to_screen(thread, x, y)
		loc = thread.runner.display.x_do.active_window.location
		return x + loc[0].to_i, y + loc[1].to_i
	end
	def self.coord_screen_to_relative(thread, x, y)
		loc = thread.runner.display.x_do.active_window.location
		return x - loc[0].to_i, y - loc[1].to_i
	end
end