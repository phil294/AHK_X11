# Send, Keys
class Cmd::X11::Keyboard::Send < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		hotkey = thread.hotkey
		# TODO: tests for all tweaks
		thread.runner.display.pause do # to prevent hotkey from triggering other hotkey or itself
			active_modifiers = thread.runner.display.x_do.active_modifiers
			# Clearing is *always* necessary, even if we want to keep the modifiers in blind mode, in which
			# case they are sent along yet again. Otherwise e.g. `^a::send {blind}b` fails. I don't know why.
			# Perhaps it's also only Ctrl that needs to be released once for Ctrl+x hotkeys to work, because
			# when I tested it, it didn't apply to Alt+x hotkeys.
			thread.runner.display.x_do.clear_active_modifiers active_modifiers
			if hotkey && ! hotkey.no_grab
				active_modifiers.reject! do |mod|
					# We don't want to restore a modifier if it came from the hotkey itself. This would
					# essentially undo the grabbing.
					mod.code == hotkey.keycode
				end
			end
			blind = nil
			thread.parse_key_combinations_to_charcodemap(args[0]) do |key_map, pressed, mouse_button, combo|
				# Our parser allows for each char having their own `{blind}` modifier, but
				# the specs only allow it at the very start:
				if blind == nil
					blind = combo.blind
					if blind
						thread.runner.display.x_do.set_active_modifiers active_modifiers
					end
				end
				if mouse_button
					if pressed
						thread.runner.display.x_do.mouse_down mouse_button
					else
						thread.runner.display.x_do.mouse_up mouse_button
					end
				else
					if hotkey && combo.keysym == hotkey.keysym && thread.runner.display.pressed_keys.includes?(combo.keysym)
						# https://github.com/jordansissel/xdotool/issues/210 (see also hotkeys.cr)
						# Not a super great solution because for every key up/down combo of the hotkey, this will
						# *always* send a second key up event now, but oh well it works
						hotkey_key_up = XDo::LibXDo::Charcodemap.new
						hotkey_key_up.code = hotkey.keycode
						thread.runner.display.x_do.keys_raw [hotkey_key_up], pressed: false, delay: 0
					end
					if [::X11::XK_Control_L, ::X11::XK_Control_R, ::X11::XK_Shift_L, ::X11::XK_Shift_R, ::X11::XK_Alt_L, ::X11::XK_Alt_R].includes?(combo.keysym)
						# TODO: this is just a workaround so that e.g. `Send, {Ctrl up}` doesn't fail due to
						# the `set_active_modifiers` at the end. Rework this once on evdev branch.
						blind = true
					end
					thread.runner.display.x_do.keys_raw key_map, pressed: pressed, delay: 0
				end
				if pressed
					sleep thread.settings.key_press_duration.milliseconds if thread.settings.key_press_duration > -1
				else
					sleep thread.settings.key_delay.milliseconds if thread.settings.key_delay > -1
				end
			end
			if ! blind
				# We can't use `x_do.set_active_modifiers active_modifiers` here like above because while it would be
				# the preferred method, it also does some `xdo_mouse_down()` internally, based on current input state.
				# And when we've sent an `{LButton}` down+up event in the keys, the x11 server might still report for the button
				# to be pressed down when the up event hasn't been processed yet by it, resulting in wrong input state and
				# effectively a wrong button pressed again by libxdo.
				thread.runner.display.x_do.keys_raw active_modifiers, pressed: true, delay: 0
			end
		end
	end
end