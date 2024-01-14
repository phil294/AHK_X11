# SetKeyDelay [, Delay, PressDuration]
class Cmd::X11::Keyboard::SetKeyDelay < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 2 end
	def run(thread, args)
		thread.settings.key_delay = args[0].to_i if args[0]? && ! args[0].empty? && args[0].to_i?
		thread.settings.key_press_duration = args[1].to_i if args[1]? && ! args[1].empty? && args[1].to_i?
	end
end