# SendRaw, Keys
# todo move these out of x11 folders, maybe remove x11 folder altogether
class Cmd::X11::Keyboard::SendRaw < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		# FIXME reactivate
		# thread.runner.display.pause do # to prevent hotkey from triggering other hotkey or itself
			thread.runner.display.adapter.send_raw(thread, args[0])
		# end
	end
end