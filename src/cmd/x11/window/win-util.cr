# todo this file doesn't belong here
# atspi Accessibles match and Windows match have a many-to-many relationship. So we can search for one
# accessible based on a list of windows (e.g. those matched by PID like match_top_level_accessible
# e.g. via ControlClick) or for one window based on a list of accessibles regarding text match
# (e.g. a window with any respective accessible found where text match/exclude matched like match_win
# e.g. via `WinActivate, , text`)
# fixme: instead of all those distinctions between x11 and evdev in this file this should be an abstract class and   proper sublcassing instead
class Cmd::X11::Window::Util
	# TODO: rename match criteria or similar?
	class WindowLike
		getter id : UInt64?
		getter name : ::String?
		getter pid : Int32?
		getter size : Tuple(UInt32, UInt32)?
		def initialize(@id,@name,@pid,@size) end
	end

	private def self.parse_match_conditions(thread, match_conditions, empty_is_last_found, a_is_active)
		first_arg = match_conditions[0]? || ""
		if match_conditions.size == 0 || match_conditions.all? &.empty?
			raise Run::RuntimeException.new "expected window matching arguments as 'last found window' cannot be inferred here" if ! empty_is_last_found
			shortcut = thread.settings.last_found_window
		elsif first_arg.downcase == "a"
			raise Run::RuntimeException.new "expected window matching arguents as 'A' for active window cannot be inferred here" if ! a_is_active
			shortcut = thread.runner.display.x_do.active_window.window
		elsif first_arg.starts_with?("ahk_id ")
			shortcut = first_arg[7..].to_u64?
			raise Run::RuntimeException.new "ahk_id must be a number" if ! shortcut
		else
			match_text = match_conditions[1]?
			exclude_title = match_conditions[2]?
			exclude_text = match_conditions[3]?
			# fixme: multiples should be possible so the logic of those three next lines is not quite correct
			match_class = first_arg[10..] if first_arg.starts_with?("ahk_class ")
			match_pid = first_arg[8..].to_i? if first_arg.starts_with?("ahk_pid ")
			match_title = first_arg if ! match_class && ! match_pid
		end
		return shortcut, match_title, exclude_title, match_class, match_pid, match_text, exclude_text
	end

	# Find a single window. Will fail outside of X11.
	# param `match_conditions` is those four `[, WinTitle, WinText, ExcludeTitle, ExcludeText]`
	# from the docs that are used in various window commands,
	# and can consequently also be an empty array.
	# todo change return type so no wrapping is required for caller
	def self.match_win(thread, match_conditions, *, empty_is_last_found = true, a_is_active = true)
		shortcut, match_title, exclude_title, match_class, match_pid, match_text, exclude_text = parse_match_conditions(thread, match_conditions, empty_is_last_found, a_is_active)
		if shortcut
			# fixme: automated tests for everything, x11+evdev
			win = win_id_to_win?(thread, shortcut)
		else
			wins = match_wins(thread, match_title: match_title, exclude_title: exclude_title, match_class: match_class, match_pid: match_pid)
			if match_text && ! match_text.empty? || exclude_text && ! exclude_text.empty?
				win = wins.find do |w|
					!!thread.runner.display.at_spi &.find_top_level_accessible(thread, [w], match_text: match_text, exclude_text: exclude_text)
				end
			else
				win = wins.first
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
	# Find a single top level accessible which in X11 would correspond to a window.
	# But also works on Wayland as atspi is display manager independent.
	# Param `match_conditions` is those four `[, WinTitle, WinText, ExcludeTitle, ExcludeText]`
	# from the docs that are used in various window commands,
	# and can consequently also be an empty array. On Wayland only name and ahk_pid and ahk_id are supported.
	def self.match_top_level_accessible(thread, match_conditions, *, empty_is_last_found = true, a_is_active = true)
		shortcut, match_title, exclude_title, match_class, match_pid, match_text, exclude_text = parse_match_conditions(thread, match_conditions, empty_is_last_found, a_is_active)

		wins = [] of WindowLike
		if shortcut
			if thread.runner.display.adapter_x11?
				win = win_id_to_win?(thread, shortcut)
				wins = [win] if win
			else
				# todo isnt shortcut a win id? either way docs necessary
				tl_acc = thread.cache.top_level_accessible_by_hash[shortcut]
			end
		else
			if thread.runner.display.adapter_x11?
				wins = match_wins(thread, match_title: match_title, exclude_title: exclude_title, match_class: match_class, match_pid: match_pid)
			else
				# TODO exclude_title unused
				wins = [ WindowLike.new(nil,match_title,match_pid,nil) ]
			end
		end

		if ! tl_acc
			tl_acc = thread.runner.display.at_spi &.find_top_level_accessible(thread, wins, match_text: match_text, exclude_text: exclude_text)
		end
		if tl_acc
			thread.cache.top_level_accessible_by_hash[tl_acc.hash] = tl_acc
			thread.cache.accessible_by_class_nn_by_top_level_accessible[tl_acc.hash] ||= {} of ::String => ::Atspi::Accessible
			yield tl_acc
		end
		!!tl_acc
	end

	# x11
	private def self.match_wins(thread, *, match_title, exclude_title, match_class = nil, match_pid = nil)
		wins = thread.runner.display.x_do.search do
			require_all
			only_visible # if not present, this can seem unpredictable and buggy to the user https://github.com/jordansissel/xdotool/issues/67#issuecomment-1193573254
			# ^ link also explains the need for specifying desktop:
			desktop thread.runner.display.x_do.desktop.to_i32
			# TODO: these/name etc should all be case sensitive. Maybe double filter below? How performant is querying for .name etc?
			window_class_name match_class if match_class # TODO: is this regex? how to make partial matches like ahk?
			window_name match_title if match_title # todo same as above / seems to be partial match but only at *start* of string
			pid match_pid if match_pid
		end.reject &.name.nil?
		if exclude_title && ! exclude_title.empty?
			wins.reject! &.name.not_nil!.includes?(exclude_title)
		end
		wins
	end
	# x11
	private def self.win_id_to_win?(thread, wid)
		win = XDo::Window.new(thread.runner.display.x_do.xdo_p, wid)
		win = nil if ! win.name
		win
	end

	# x11
	def self.coord_relative_to_screen(thread, x : Int32, y : Int32)
		loc = thread.runner.display.x_do.active_window.location
		return x + loc[0].to_i, y + loc[1].to_i
	end
	# x11
	def self.coord_screen_to_relative(thread, x, y)
		loc = thread.runner.display.x_do.active_window.location
		return x.to_i - loc[0].to_i, y.to_i - loc[1].to_i
	end
end