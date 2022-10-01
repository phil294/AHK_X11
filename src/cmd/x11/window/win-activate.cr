require "./win-util"

class Cmd::X11::Window::WinActivate < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def run(thread, args)
		*match_conditions = args
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: false) do |win|
			# TODO: "Six attempts will be made to activate the target window over the course of 60ms. Thus, it is usually unnecessary to follow it with the WinWaitActive"
			# activate alone works *most of the time*, but sometimes raise is also necessary... I have no idea
			win.activate!
			win.focus!
			win.raise!
		end
	end
end