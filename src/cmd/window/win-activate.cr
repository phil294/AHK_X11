require "../base"
require "./win-util"

module Cmd
	module Window
		class WinActivate < Base
			def self.min_args; 0 end
			def self.max_args; 4 end
			def run(thread)
				win = Util.match(thread, @args[0..], empty_is_last_found: true, a_is_active: false)
				return if ! win
				win.activate!
			end
		end
	end
end