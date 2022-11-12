require "../window/win-util"

class Cmd::X11::Mouse::ControlClick < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 8 end
	def self.sets_error_level; true end
	def run(thread, args)
		class_nn_or_text = args[0]
		args.delete_at(0)
		args.delete_at(2) if args[2]?
		count = args[2]?.try &.to_i? || 1
		args.delete_at(2) if args[2]?
		args.delete_at(2) if args[2]?

		Cmd::X11::Window::Util.match(thread, args, empty_is_last_found: true, a_is_active: true) do |win|
			frame = thread.runner.at_spi.find_window(pid: win.pid, window_name: win.name)
			return "1" if ! frame
			acc = thread.runner.at_spi.find_descendant(frame, class_nn_or_text)
			return "1" if ! acc
			count.times do
				success = thread.runner.at_spi.click(acc)
				return "1" if ! success
			end
		end
		"0"
	end
end