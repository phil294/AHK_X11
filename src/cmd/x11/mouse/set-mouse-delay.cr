# SetMouseDelay, Delay
class Cmd::X11::Mouse::SetMouseDelay < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.settings.mouse_delay = args[0].to_i if args[0].to_i?
	end
end