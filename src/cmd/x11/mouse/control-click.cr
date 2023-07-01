require "../window/win-util"
# ControlClick, Control-or-Pos [, WinTitle, WinText, WhichButton, ClickCount, Options, ExcludeTitle, ExcludeText]
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

		Cmd::X11::Window::Util.match_top_level_accessible(thread, args) do |tl_acc|
			success = thread.runner.display.at_spi do |at_spi|
				acc = at_spi.find_descendant_of_top_level_accessible(thread, tl_acc, class_nn_or_text)
				if acc
					count.times do
						s = at_spi.click(acc)
						next "1" if ! s
					end
					true
				end
			end
			return "1" if ! success
		end
		"0"
	end
end