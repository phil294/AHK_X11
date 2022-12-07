require "../window/win-util"

class Cmd::X11::Mouse::ControlGetText < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var = args[0]
		class_nn_or_text = args[1]? || return
		args.delete_at(0)
		args.delete_at(0)
		Cmd::X11::Window::Util.match(thread, args, empty_is_last_found: true, a_is_active: true) do |win|
			txt = thread.runner.display.at_spi do |at_spi|
				desc, _, _ = at_spi.find_descendant(thread, win, class_nn_or_text)
				if desc
					at_spi.get_text(desc) || ""
				end
			end
			return "1" if ! txt
			thread.runner.set_user_var(out_var, txt)
		end
		"0"
	end
end