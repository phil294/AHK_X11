# Send, Keys
class Cmd::X11::Keyboard::Send < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		thread.runner.display.pause do # to prevent hotkey from triggering other hotkey or itself
			active_modifiers = thread.runner.display.x_do.active_modifiers
			thread.runner.display.x_do.clear_active_modifiers active_modifiers
			thread.parse_key_combinations_to_charcodemap(args[0]) do |key_map, pressed, mouse_button, combo|
				if mouse_button
					if pressed
						thread.runner.display.x_do.mouse_down mouse_button
					else
						thread.runner.display.x_do.mouse_up mouse_button
					end
				else
					if (hotkey = thread.hotkey) && combo.keysym == hotkey.keysym && thread.runner.display.pressed_keys.includes?(combo.keysym)
						# https://github.com/jordansissel/xdotool/issues/210 (see also hotkeys.cr)
						# Not a super great solution because for every key up/down combo of the hotkey, this will
						# *always* send a second key up event now, but oh well it works
						hotkey_key_up = XDo::LibXDo::Charcodemap.new
						hotkey_key_up.code = hotkey.keycode
						thread.runner.display.x_do.keys_raw [hotkey_key_up], pressed: false, delay: 0
					end
					thread.runner.display.x_do.keys_raw key_map, pressed: pressed, delay: 0
				end
			end
			# We can't use `x_do.set_active_modifiers active_modifiers` here because while it would be
			# the preferred method, it also does some `xdo_mouse_down()` internally, based on current input state.
			# And when we've sent an `{LButton}` down+up event in the keys, the x11 server might still report for the button
			# to be pressed down when the up event hasn't been processed yet by it, resulting in wrong input state and
			# effectively a wrong button pressed again by libxdo.
			thread.runner.display.x_do.keys_raw active_modifiers, pressed: false, delay: 0
		end
	end
end