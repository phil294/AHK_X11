module Cmd
	module Window
		private class Util
			# param args is those four [, WinTitle, WinText, ExcludeTitle, ExcludeText] from the docs
			# and consequently also be an empty array
			protected def self.match(thread, args, *, empty_is_last_found, a_is_active)
				title = thread.runner.str(args[0]? || "")
				if args.size == 0
					return thread.settings.last_found_window if empty_is_last_found
					raise RuntimeException.new "expected window matching arguments as 'last found window' cannot be inferred here"
				elsif title == "A" && args.size == 1
					return thread.runner.x_do.active_window if a_is_active
					raise RuntimeException.new "expected window matching arguents as 'A' for active window cannot be inferred here"
				else
					# text = thread.runner.str(args[1]? || "") # todo
					exclude_title = thread.runner.str(args[2]? || "")
					# exclude_text = thread.runner.str(args[3]? || "") # todo

					# broken: https://github.com/woodruffw/x_do.cr/issues/10
					wins = thread.runner.x_do.search do
						require_all
						if title.starts_with?("ahk_class ")
							window_class_name title[10..] # todo is this regex? how to make partial matches like ahk?
						elsif title.starts_with?("ahk_id ")
							id = title[7..].to_i?(strict: true)
							raise RuntimeException.new "ahk_id must be a number" if ! id
							pid id # todo should be win id instead (?) but xdo apparently doesn't provide a method for that?
						else
							window_name title
						end
					end
					wins.reject! &.name.includes? exclude_title if ! exclude_title.empty?
					return wins.first?
				end
			end
		end
	end
end