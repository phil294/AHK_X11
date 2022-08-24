require "../../base"
require "./win-util"

class Cmd::X11::Window::WinClose < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 5 end
	def run(thread, args)
		Util.match(thread, [args[0]?, args[1]?, args[3]?, args[4]?], empty_is_last_found: true, a_is_active: true) do |win|
			win.close!
		end
	end
end