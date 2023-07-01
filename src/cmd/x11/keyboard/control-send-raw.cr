# ControlSendRaw [, Control, Keys, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Keyboard::ControlSendRaw < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		control_class_nn_or_text, keys, *match_conditions = args
		if ! control_class_nn_or_text
			# todo: should be: regardless of inputdevice, search for first?focused? acc and
			# try to send text to it. if fails, then onyl on x11, do win.type as below.
			if ! thread.runner.display.is_x11
				# todo probably not true, can just determine the currently focused one?
				raise Run::RuntimeException.new "ControlSendRaw can only be used together with a specific control on non-X11 systems like your seems to be"
			end
			Cmd::X11::Window::Util.match_win(thread, match_conditions) do |win|
				thread.runner.display.pause do
					win.clear_active_modifiers thread.runner.display.x_do.active_modifiers
					win.type keys
				end
			end
		else
			Cmd::X11::Window::Util.match_top_level_accessible(thread, match_conditions) do |tl_acc|
				thread.runner.display.at_spi do |at_spi|
					acc = at_spi.find_descendant_of_top_level_accessible(thread, tl_acc, control_class_nn_or_text)
					at_spi.set_text(acc, keys) if acc
				end
			end
		end
	end
end