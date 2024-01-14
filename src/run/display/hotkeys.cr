require "x11"

module Run
	# Manages, calls, pauses, suspends Hotkeys
	class Hotkeys
		@runner : Runner

		def initialize(@runner)
		end

		def run
			@runner.display.register_key_listener do |key_event, keysym, is_paused|
				handle_event(key_event, keysym, is_paused)
			end
			@runner.display.on_pause { pause }
			@runner.display.on_resume { resume }
			@runner.display.on_suspend { suspend }
			@runner.display.on_unsuspend { unsuspend }
		end

		@hotkeys = [] of Hotkey
		def add(hotkey_definition : HotkeyDefinition, *, subscribe = true)
			cmd = @runner.labels[hotkey_definition.label.downcase]
			keysym = @runner.display.adapter.key_combination_to_keysym(hotkey_definition)
			raise Run::RuntimeException.new "key name '#{hotkey_definition.key_name}' not found" if ! keysym
			hotkey = Hotkey.new(hotkey_definition, cmd, keysym, 0)
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
		def add_or_update(*, key_str, label, priority, active_state = nil)
			if label
				cmd = @runner.labels[label]?
				raise RuntimeException.new "Add or update Hotkey: Label '#{label}' not found" if ! cmd
			end
			hotkey = @hotkeys.find { |h| h.key_str == key_str }
			if hotkey
				remove(hotkey)
				active_state = hotkey.active if active_state.nil?
			else
				raise RuntimeException.new "Nonexistent Hotkey.\n\nSpecifically: #{key_str}" if ! label
				# these two lines are duplicate with parser. todo?
				key_combo = Util::AhkString.parse_key_combinations(key_str.gsub("*","").gsub("~",""), @runner.settings.escape_char, implicit_braces: true)[0]?
				raise RuntimeException.new "Hotkey '#{key_str}' not understood" if ! key_combo
				keysym = @runner.display.adapter.key_combination_to_keysym(key_combo)
				raise RuntimeException.new "Hotkey '#{key_str}' not understood" if ! keysym
				hotkey = Hotkey.new(key_str, label, key_combo, cmd.not_nil!, keysym, priority, max_threads: @runner.settings.max_threads_per_hotkey)
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

		def handle_event(key_event, keysym, is_paused)
			return if is_paused

			hotkey = @hotkeys.find do |hotkey|
				hotkey.active &&
				hotkey.keysym == keysym &&
				(hotkey.up ? key_event.up : key_event.down) &&
				hotkey.modifiers_match(key_event.modifiers) &&
				(! @runner.display.suspended || hotkey.exempt_from_suspension)
			end
			if hotkey
				# FIXME: test if still works with new conditions, and write tests if they don't exist yet,
				# including expected failing test such as `f::echo 1,send g` < latter pbly outdated now
				if @runner.display.adapter_x11? && ! hotkey.up && ! hotkey.no_grab
					# Fixing https://github.com/jordansissel/xdotool/issues/210:
 					# Doing a `hotkey.keycode` UP event works great but breaks key remaps.
					# Instead, the following magic seems to work reliably, as long as the hotkey key
					# isn't sent itself (see Send for that other fix).
					# Note that both grab and ungrab may fail / not work as expected but that's fine.
					# This would better be placed at the *first* `Send`/`SendRaw` command on a per-hotkey
					# basis, but since the performance penalty is negligible and it has no negative
					# side effects, we just put it at the start of any grabbing hotkey trigger:
					@runner.display.adapter_x11.grab_keyboard
					@runner.display.adapter_x11.ungrab_keyboard
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
		# todo doesnt belong here
		def block_input
			@runner.display.adapter.grab_keyboard
		end
		def unblock_input
			@runner.display.adapter.ungrab_keyboard
		end
	end
end
