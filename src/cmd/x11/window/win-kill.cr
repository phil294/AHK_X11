require "../../base"
require "./win-util"

class Cmd::X11::Window::WinKill < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 5 end
	def run(thread, args)
		match_conditions = args
		match_conditions.delete_at(2) if args.size >= 3
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
		win.kill!
		end
	end
end