require "x11"

module Run
	# Manages, calls, pauses, suspends Hotkeys
	class Hotkeys
		@runner : Runner

		def initialize(@runner)
		end

		def run
			@runner.display.register_key_listener do |key_event, keysym, char|
				handle_event(key_event, keysym, char)
			end
			@runner.display.on_pause { pause }
			@runner.display.on_suspend { resume }
			@runner.display.on_suspend { suspend }
			@runner.display.on_unsuspend { unsuspend }
		end

		@hotkeys = [] of Hotkey
		def add(hotkey, subscribe = true)
			# apparently keycodes are display-dependent so they can't be determined at build time. TODO: check this or change, fix type cast:
			hotkey.keycode = @runner.display.adapter.as(X11).keysym_to_keycode(hotkey.keysym)
			if subscribe
				@hotkeys << hotkey
			end
			if ! hotkey.no_grab
				@runner.display.adapter.grab_hotkey(hotkey)
			end
		end
		def remove(hotkey, unsubscribe = true)
			@runner.display.adapter.ungrab_hotkey(hotkey)
			if unsubscribe
				@hotkeys.delete hotkey
			end
		end
		def add_or_update(*, hotkey_label, cmd_label, priority, active_state = nil)
			if cmd_label
				cmd = @runner.labels[cmd_label]?
				raise RuntimeException.new "Add or update Hotkey: Label '#{cmd_label}' not found" if ! cmd
			end
			hotkey = @hotkeys.find { |h| h.key_str == hotkey_label }
			if hotkey
				remove(hotkey)
				active_state = hotkey.active if active_state.nil?
			else
				raise RuntimeException.new "Nonexistent Hotkey.\n\nSpecifically: #{hotkey_label}" if ! cmd_label
				hotkey = Hotkey.new(cmd.not_nil!, hotkey_label, priority: priority, escape_char: @runner.settings.escape_char)
				hotkey.exempt_from_suspension = cmd.is_a?(Cmd::Misc::Suspend)
				@hotkeys << hotkey
				active_state = true if active_state.nil?
			end
			hotkey.cmd = cmd if cmd
			hotkey.priority = priority if priority
			if active_state
				add(hotkey)
				hotkey.active = true
			else
				hotkey.active = false
			end
			hotkey
		end

		def handle_event(key_event, keysym, char)
			up = key_event.type == ::X11::KeyRelease || key_event.type == ::X11::ButtonRelease # TODO: externalize somehow because this is duplicate in various places

			hotkey = @hotkeys.find do |hotkey|
				hotkey.active &&
				hotkey.keysym == keysym &&
				hotkey.up == up &&
				(hotkey.modifier_variants.any? &.== key_event.state) &&
				(! @runner.display.suspended || hotkey.exempt_from_suspension)
			end
			if hotkey
				if ! hotkey.up && ! hotkey.no_grab
					# Fix https://github.com/jordansissel/xdotool/pull/406#issuecomment-1280013095
					key_map = XDo::LibXDo::Charcodemap.new
					key_map.code = hotkey.keycode
					@runner.display.x_do.keys_raw [key_map], pressed: false, delay: 0
				end
				hotkey.trigger(@runner)
			end
		end

		def pause
			@hotkeys.each do |hotkey|
				remove hotkey, unsubscribe: false
			end
		end
		def resume
			@hotkeys.each do |hotkey|
				add hotkey, subscribe: false
			end
		end
		def suspend
			@hotkeys.each do |hotkey|
				if ! hotkey.exempt_from_suspension
					remove hotkey, unsubscribe: false
				end
			end
		end
		def unsuspend
			@hotkeys.each do |hotkey|
				if ! hotkey.exempt_from_suspension
					add hotkey, subscribe: false
				end
			end
		end
		def block_input
			@runner.display.adapter.grab_keyboard
		end
		def unblock_input
			@runner.display.adapter.ungrab_keyboard
		end
	end
end
