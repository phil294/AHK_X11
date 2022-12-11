require "../window/win-util"

class Cmd::X11::Mouse::ControlSetText < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def self.sets_error_level; true end
	def run(thread, args)
		class_nn_or_text = args[0]
		new_text = args[1]
		args.delete_at(0)
		args.delete_at(0)
		Cmd::X11::Window::Util.match(thread, args, empty_is_last_found: true, a_is_active: true) do |win|
			success = thread.runner.display.at_spi do |at_spi|
				acc = at_spi.find_descendant(thread, win, class_nn_or_text)
				if acc
					at_spi.set_text(acc, new_text)
				end
				false
			end
			return "1" if ! success
		end
		"0"
	end
end