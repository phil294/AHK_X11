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
			win = thread.runner.x_do.active_window
		else
			text = match_conditions[1]? || ""
			exclude_title = match_conditions[2]? || ""
			exclude_text = match_conditions[3]? || ""
			current_desktop = thread.runner.x_do.desktop.to_i32

			wid = nil
			# broken: https://github.com/woodruffw/x_do.cr/issues/10
			wins = thread.runner.x_do.search do
				require_all
				only_visible # if not present, this can seem unpredictable and buggy to the user https://github.com/jordansissel/xdotool/issues/67#issuecomment-1193573254
				# ^ link also explains the need for specifying desktop:
				desktop current_desktop
				# TODO: these should all be case sensitive. Maybe double filter below? How performant is querying for .name etc?
				if title.starts_with?("ahk_class ")
					window_class_name title[10..] # TODO: is this regex? how to make partial matches like ahk?
				elsif title.starts_with?("ahk_id ")
					wid = title[7..].to_u64?
					raise Run::RuntimeException.new "ahk_id must be a number" if ! wid
					# No way to search by ID currently, so get all and filter below
				else
					window_name title # todo same as above / seems to be partial match but only at *start* of string
				end
			end.reject &.name.nil?

			if ! wid.nil?
				win = wins.find { |win| win.window == wid }
			else
				wins.select! do |win|
					if ! exclude_title.empty?
						return false if win.name.not_nil!.includes? exclude_title 
					end
					if ! text.empty? || ! exclude_text.empty?
						win_texts = [] of ::String
						frame = thread.runner.at_spi.find_window(pid: win.pid, window_name: win.name)
						if frame
							win_texts = thread.runner.at_spi.get_all_texts(frame, include_hidden: false)
						end
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
			thread.runner.x_do.focused_window sane: false
		end
		!!win
	end
end