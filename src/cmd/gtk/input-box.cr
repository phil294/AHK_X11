# InputBox, OutputVar [, Title, Prompt, Hide, Width, Height, X, Y, ~Font~, Timeout, Default]
class Cmd::Gtk::Inputbox < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 11 end
	def self.sets_error_level; true end
	def run(thread, args)
		ret = thread.runner.display.gtk.inputbox(args[1]?, args[2]?, args[3]?.try &.downcase == "hide", args[4]?.try &.to_i?, args[5]?.try &.to_i?, args[6]?.try &.to_i?, args[7]?.try &.to_i?, args[9]?.try &.to_f?, args[10]? || "")
		case ret[:status]
		when Run::Gtk::MsgBoxButton::Cancel
			thread.runner.set_user_var(args[0], ret[:response])
			"1"
		when Run::Gtk::MsgBoxButton::Timeout
			"2"
		# when Run::Gtk::MsgBoxButton::OK
		else
			thread.runner.set_user_var(args[0], ret[:response])
			"0"
		end
	end
end