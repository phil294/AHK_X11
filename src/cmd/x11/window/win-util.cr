class Cmd::Window::Util
	# Find a single window.
	# param `match_conditions` is those four `[, WinTitle, WinText, ExcludeTitle, ExcludeText]`
	# from the docs that are used in various window commands,
	# and consequently also be an empty array.
	# INCOMPAT: text/excludetext is ignored
	protected def self.match(thread, match_conditions, *, empty_is_last_found, a_is_active)
		title = match_conditions[0]? || ""
		if match_conditions.size == 0
			return thread.settings.last_found_window if empty_is_last_found
			raise Run::RuntimeException.new "expected window matching arguments as 'last found window' cannot be inferred here"
		elsif title == "A" && match_conditions.size == 1
			return thread.runner.x_do.active_window if a_is_active
			raise Run::RuntimeException.new "expected window matching arguents as 'A' for active window cannot be inferred here"
		else
			exclude_title = match_conditions[2]? || ""

			wid = nil
			# broken: https://github.com/woodruffw/x_do.cr/issues/10
			wins = thread.runner.x_do.search do
				require_all
				only_visible # if not present, this can seem unpredictable and buggy to the user https://github.com/jordansissel/xdotool/issues/67#issuecomment-1193573254
				if title.starts_with?("ahk_class ")
					window_class_name title[10..] # TODO: is this regex? how to make partial matches like ahk?
				elsif title.starts_with?("ahk_id ")
					wid = title[7..].to_u64?(strict: true)
					raise Run::RuntimeException.new "ahk_id must be a number" if ! wid
					# No way to search by ID currently, so get all and filter below
				else
					window_name title
				end
			end.reject &.name.nil?

			return wins.find { |win| win.window == wid } if ! wid.nil?

			wins.reject! &.name.not_nil!.includes? exclude_title if ! exclude_title.empty?

			return wins.first?
		end
	end
end