require "../window/win-util"
# ControlGetText, OutputVar [, Control, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Mouse::ControlGetText < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var = args[0]
		class_nn_or_text = args[1]? || return
		args.delete_at(0)
		args.delete_at(0)
		success = false
		Cmd::X11::Window::Util.match_top_level_accessible(thread, args) do |tl_acc|
			thread.runner.display.at_spi do |at_spi|
				acc = at_spi.find_descendant_of_top_level_accessible(thread, tl_acc, class_nn_or_text)
				if acc
					txt = at_spi.get_text(acc) || ""
					thread.runner.set_user_var(out_var, txt)
					success = true
				end
			end
		end
		return success ? "0" : "1"
	end
end