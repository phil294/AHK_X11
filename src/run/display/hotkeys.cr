require "x11"

module Run
	# Manages, calls, pauses, suspends Hotkeys
	class Hotkeys
		@runner : Runner

		def initialize(@runner)
		end

		def run
			@runner.display.register_key_listener do |key_event, keysym, char, is_paused|
				handle_event(key_event, keysym, char, is_paused)
			end
			@runner.display.on_pause { pause }
			@runner.display.on_resume { resume }
			@runner.display.on_suspend { suspend }
			@runner.display.on_unsuspend { unsuspend }
		end

		@hotkeys = [] of Hotkey
		def add(hotkey, *, subscribe = true)
			# apparently keycodes are display-dependent so they can't be determined at build time. TODO: check this or change, fix type cast:
			hotkey.keycode = @runner.display.adapter.as(X11).keysym_to_keycode(hotkey.keysym)
			if subscribe
				@hotkeys << hotkey
			end
			if ! hotkey.no_grab
				@runner.display.adapter.grab_hotkey(hotkey)
			end
		end
		def remove(hotkey, *, unsubscribe = true)
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
				hotkey = Hotkey.new(cmd.not_nil!, hotkey_label, priority: priority, escape_char: @runner.settings.escape_char, max_threads: @runner.settings.max_threads_per_hotkey)
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

		def handle_event(key_event, keysym, char, is_paused)
			return if is_paused
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
					# Fixing https://github.com/jordansissel/xdotool/issues/210: (also see Send/SendRaw)
 					# Doing a `hotkey.keycode` UP event works great but breaks key remaps.
					# Instead, the following magic seems to work reliably.
					# Note that both grab and ungrab may fail / not work as expected but that's fine.
					# This would better be placed at the *first* `Send`/`SendRaw` command on a per-hotkey
					# basis, but since the performance penalty is negligible and it has no negative
					# side effects, we just put it at the start of any grabbing hotkey trigger:
					@runner.display.adapter.as(X11).grab_keyboard
					@runner.display.adapter.as(X11).ungrab_keyboard
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
