require "../window/win-util"
# ControlSetText, Control, NewText [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Mouse::ControlSetText < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	def self.sets_error_level; true end
	def run(thread, args)
		class_nn_or_text = args[0]
		new_text = args[1]
		args.delete_at(0)
		args.delete_at(0)
		success = false
		Cmd::X11::Window::Util.match_top_level_accessible(thread, args) do |tl_acc|
			success = thread.runner.display.at_spi do |at_spi|
				acc = at_spi.find_descendant_of_top_level_accessible(thread, tl_acc, class_nn_or_text)
				if acc
					at_spi.set_text(acc, new_text)
					success = true
				end
			end
		end
		return success ? "0" : "1"
	end
end