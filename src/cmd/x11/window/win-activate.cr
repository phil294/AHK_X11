require "../../base"
require "./win-util"

class Cmd::Window::WinActivate < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread)
		win = Util.match(thread, @args[0..], empty_is_last_found: true, a_is_active: false)
		return if ! win
		# TODO: incompat: Six attempts will be made to activate the target window over the course of 60ms. Thus, it is usually unnecessary to follow it with the WinWaitActive 
		win.activate!
	end
end