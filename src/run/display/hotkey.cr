require "../key-combination"

module Run
	class Hotkey < KeyCombination
		getter key_str : String # TODO: rename label
		property cmd : Cmd::Base?
		property priority : Int32
		property active = true
		getter modifier_variants = [] of UInt32
		getter no_grab = false
		property exempt_from_suspension = false
		getter max_threads : UInt8
		@threads = [] of Thread
		def initialize(@key_str, *, @priority, escape_char, @max_threads)
			init(escape_char)
		end
		def initialize(@cmd, @key_str, *, @priority, escape_char, @active = true, @max_threads)
			init(escape_char)
		end

		# TODO: all of this is x11 specific and shouldn't be in this file. probably best just recompute every time it's needed inside x11.cr:(un)grab_key
		@@available_modifier_combinations : Array(Int32)
		# TODO: this can probably be done much easier, it's just all possible combinations of all possible sizes >= 1 of all relevant modifiers. Could actually also be a macro except that then you'd need the integers directly, not the X11 synonyms
		@@available_modifier_combinations =
			[1,2,3,4,5].reduce([] of Array(Int32)) do |all, i|
				# ctrl, shift, 1=alt, 4=super, 5=altgr, 2=numlock
				[::X11::ControlMask, ::X11::ShiftMask, ::X11::Mod1Mask, ::X11::Mod4Mask, ::X11::Mod5Mask, ::X11::Mod2Mask].combinations(i).each do |mod_combo|
					all << mod_combo
				end
				all
			end.map &.reduce(0) do |all, v|
				all |= v
				all
			end

		# In X11, numlock is a modifier (Mod2Mask) that always needs to be included in the grab
		# variations, as X11 sees e.g. A as a different hotkey than NumLock+A.
		# However, for the keys positioned on the Numpad block itself, this generalization
		# does not apply as the functionality (keycode) indeed depends on the state of NumLock.
		# - Num0 to 9 and dot/comma require NumLock OFF
		# - NumIns, Del, Home etc. require NumLock ON
		# - NumEnter, Add, Sub, Del, Mult keysyms normally don't care for NumLock state except
		#   on very rare keyboards where they will instead map to Equals, Zoom, Copy etc.
		#   For our purposes, this doesn't matter, as per AHK spec, the latter keys don't exist.
		private def is_numpad_with_numlock_only(keysym)
			keysym == ::X11::XK_KP_0 || keysym == ::X11::XK_KP_1 || keysym == ::X11::XK_KP_2 || keysym == ::X11::XK_KP_3 || keysym == ::X11::XK_KP_4 || keysym == ::X11::XK_KP_5 || keysym == ::X11::XK_KP_6 || keysym == ::X11::XK_KP_7 || keysym == ::X11::XK_KP_8 || keysym == ::X11::XK_KP_9 ||
			# Grabbing this one somehow doesn't seem to work, although the key detection etc. is fine
			keysym == ::X11::XK_KP_Decimal
			# || keysym == ::X11::XK_KP_Separator # doesn't exist in AHK
			# Always active, see above:
			# || ::X11::XK_KP_Multiply || keysym == ::X11::XK_KP_Add || keysym == ::X11::XK_KP_Subtract || keysym == ::X11::XK_KP_Divide || keysym == ::X11::XK_KP_Enter
		end
		# :ditto:
		private def is_numpad_without_numlock_only(keysym)
			keysym == ::X11::XK_KP_Home || keysym == ::X11::XK_KP_Left || keysym == ::X11::XK_KP_Up || keysym == ::X11::XK_KP_Right || keysym == ::X11::XK_KP_Down || keysym == ::X11::XK_KP_Page_Up || keysym == ::X11::XK_KP_Page_Down || keysym == ::X11::XK_KP_End || keysym == ::X11::XK_KP_Begin || keysym == ::X11::XK_KP_Insert || keysym == ::X11::XK_KP_Delete
			# Don't exist in AHK:
			# || ::X11::XK_KP_Space || keysym == ::X11::XK_KP_Tab || keysym == ::X11::XK_KP_F1 || keysym == ::X11::XK_KP_F2 || keysym == ::X11::XK_KP_F3 || keysym == ::X11::XK_KP_F4 || keysym == ::X11::XK_KP_Prior || keysym == ::X11::XK_KP_Next || keysym == ::X11::XK_KP_Equal
		end

		def init(escape_char)
			key_combos = Util::AhkString.parse_key_combinations(@key_str.downcase.gsub("*","").gsub("~",""), escape_char, implicit_braces: true)
			raise Run::RuntimeException.new "Multiple keys aren't allowed for Hotkey definitions" if key_combos.size != 1 # TODO: probably impossible?
			@key_name = key_combos[0].key_name
			@keysym = key_combos[0].keysym
			@modifiers = key_combos[0].modifiers
			@up = key_combos[0].up

			@no_grab = true if @key_str.includes? '~'
			@modifier_variants << @modifiers if ! is_numpad_with_numlock_only(@keysym)
			@modifier_variants << (@modifiers | ::X11::Mod2Mask.to_u32) if ! is_numpad_without_numlock_only(@keysym)
			if @key_str.includes? '*' # wildcard
				@@available_modifier_combinations.each do |other|
					if ! @modifier_variants.includes? (modifiers | other)
						@modifier_variants << (@modifiers | other)
					end
				end
			end
		end
		def trigger(runner)
			@threads.reject! &.done
			# TODO: (commands not implemented yet):
			# && ! @cmd_is_a?(Cmd::KeyHistory) && ! @cmd_is_a?(Cmd::ListLines) && ! @cmd_is_a?(Cmd::ListVars) && ! @cmd_is_a?(ListHotkeys)
			if @threads.size >= @max_threads && ! @cmd.is_a?(Cmd::ControlFlow::ExitApp) && ! @cmd.is_a?(Cmd::Misc::Pause) && ! @cmd.is_a?(Cmd::Gtk::Edit) && ! @cmd.is_a?(Cmd::Misc::Reload)
				# TODO: logger warn? what does win ahk do?
				STDERR.puts "WARN: Skipping thread for hotkey press '#{key_str}' because #{@threads.size} threads are already running (max_threads==#{@max_threads}"
				return
			end
			thread = runner.not_nil!.add_thread @cmd.not_nil!, @key_str, @priority, hotkey: self
			@threads << thread
		end
	end
end