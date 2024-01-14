# ControlSend [, Control, Keys, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Keyboard::ControlSend < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		control_class_nn_or_text, keys, *match_conditions = args
		# todo: incomplete
		# todo: update docs: recommend controlsendraw because it can use a11y if configured properly and because win.keys_raw often doesnt work, but that doesn't work with key combos like ^c
		if ! control_class_nn_or_text
			if ! thread.runner.display.is_x11
				# todo probably not true, can just determine the currently focused one?
				raise Run::RuntimeException.new "ControlSend can only be used together with a specific control on non-X11 systems like your seems to be"
			end
			Cmd::X11::Window::Util.match_win(thread, match_conditions) do |win|
				thread.runner.display.pause do
					# todo necessary?
					win.clear_active_modifiers thread.runner.display.x_do.active_modifiers
					thread.parse_key_combinations(keys).each do |key_combo|
						thread.runner.display.adapter_x11.key_combination_to_charcodemap(key_combo) do |key_map, pressed, mouse_button|
							if ! mouse_button
								win.keys_raw key_map, pressed: pressed, delay: 0
							end
						end
					end
					if pressed
						sleep thread.settings.key_press_duration.milliseconds if thread.settings.key_press_duration > -1
					else
						sleep thread.settings.key_delay.milliseconds if thread.settings.key_delay > -1
					end
				end
			end
		else
			raise Run::RuntimeException.new "ControlSend with a specific control is not possible, please use ControlSendRaw instead."
		end
	end
end