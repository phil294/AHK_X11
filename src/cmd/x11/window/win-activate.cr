require "../../base"
require "./win-util"

class Cmd::X11::Window::WinActivate < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		*match_conditions = args
		win = Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: false)
		return if ! win
		
		# TODO: incompat: "Six attempts will be made to activate the target window over the course of 60ms. Thus, it is usually unnecessary to follow it with the WinWaitActive"

		# TODO: this seems to be a bit window manager dependent unfortunately, so for now just bruteforce
		win.raise!
		win.activate!
		win.focus!
	end
end