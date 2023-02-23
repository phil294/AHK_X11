require "./win-util"
# WinGetText, OutputVar [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinGetText < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 5 end
	def self.sets_error_level; true end
	def run(thread, args)
		match_conditions = args[1..]? || [] of ::String
		out_var = args[0]
		Util.match(thread, match_conditions, empty_is_last_found: true, a_is_active: true) do |win|
			texts = thread.runner.display.at_spi &.get_all_texts(thread, win, include_hidden: false)
			thread.runner.set_user_var(out_var, texts ? texts.join("\n") : "")
		end
		"0"
	end
end