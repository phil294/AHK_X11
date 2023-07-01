require "x_do"
require "./display/x11"
require "./display/evdev"
require "./display/key-lookup"
require "./display/hotstrings"
require "./display/hotkeys"
require "./display/pressed-keys"
require "./display/gtk"
require "./display/at-spi"

module Run
	# Groups all modules that require a running display server.
	class Display
		# TODO: atspi listener via register_keystroke_listener with ALL_WINDOWS
		@adapter : DisplayAdapter?
		@x_do : XDo?
		getter gtk : Gtk
		getter hotstrings : Hotstrings
		getter hotkeys : Hotkeys
		getter pressed_keys : PressedKeys
		getter key_lookup : KeyLookup?
		@runner : Runner
		getter is_x11 = false

		def initialize(@runner)
			if ! @runner.settings.input_interface
				@runner.settings.input_interface = InputInterface::XTest
			end
			@is_x11 = ENV["XDG_SESSION_TYPE"]? == "x11" || ! ENV["WAYLAND_DISPLAY"]? || ENV["WAYLAND_DISPLAY"].empty?
			keymap = KeyboardLayout.get_keymap
			key_lookup = KeyLookup.new(keymap)
			# todo why the condition?
			if @runner.settings.input_interface != InputInterface::Off
				@key_lookup = key_lookup
			end
			if is_x11
				@x_do = XDo.new
			end
			if is_x11 && @runner.settings.input_interface == InputInterface::XTest || @runner.settings.input_interface == InputInterface::XGrab
				{% if ! flag?(:release) %}
					puts "[debug] using input device backend: X11"
				{% end %}
				@adapter = X11.new @x_do.not_nil!, xtest: @runner.settings.input_interface == InputInterface::XTest
			elsif @runner.settings.input_interface == InputInterface::Evdev
				{% if ! flag?(:release) %}
					puts "[debug] using input device backend: Evdev"
				{% end %}
				begin
					@adapter = Evdev.new key_lookup, keymap
				rescue e : File::AccessDeniedError
					STDERR.puts e
					raise Run::RuntimeException.new "Permission denied to input device. You need to add yourself to the 'input' group, e.g. by running 'sudo usermod -aG input $USER' and potentially restarting your login session."
				end
			end
			@gtk = Gtk.new default_title: (@runner.get_global_var("a_scriptname") || "")
			@at_spi = AtSpi.new
			@hotstrings = Hotstrings.new(@runner, @runner.settings.hotstring_end_chars)
			@hotkeys = Hotkeys.new(@runner)
			@pressed_keys = PressedKeys.new(@runner)
		end

		# FIXME
		def adapter
			if @adapter
				@adapter.not_nil!
			else
				raise RuntimeException.new "This command is not available because no input device is available. Did you set #InputDevice OFF? [adapter]"
			end
		end
		def adapter_x11?
			if @adapter.is_a?(X11)
				@adapter.as(X11)
			else
				nil
			end
		end
		def adapter_x11
			adapter_x11? || raise RuntimeException.new "This command or command option is not available, it requires X11 but that is not in use. It seems you are either using Wayland or used the directive #InputDevice. [adapter_x11]"
		end
		def x_do
			if @x_do
				@x_do.not_nil!
			else
				raise RuntimeException.new "This command is not available, it requires X11 but it looks like you're on Wayland. [x_do]"
			end
		end

		def run(*, hotstrings, hotkey_definitions)
			if @adapter
				spawn do
					@adapter.not_nil!.run key_handler: ->handle_event(KeyCombination, UInt64)
				end
			end
			@hotstrings.run
			hotstrings.each { |h| @hotstrings.add h }
			@hotkeys.run
			hotkey_definitions.each { |h| @hotkeys.add h }
			@pressed_keys.run
			# Cannot use normal mt `spawn` because https://github.com/crystal-lang/crystal/issues/12392
			::Thread.new do
				gtk.run # separate worker thread because gtk loop is blocking
			end
			gtk.init(@runner)
		end

		@pause_counter = 0
		@is_paused = false
		@pause_mutex = Mutex.new
		@pause_listeners = [] of Proc(Nil)
		def on_pause(&block)
			@pause_listeners << block
		end
		# multiple threads may request a pause. Display will only resume after all have called
		# `resume` again.
		# pausing event handling can be very important in `Send` scenarios to prevent hotkeys
		# from triggering themselves (or others).
		# Please note that this `display.pause` has nothing to do with `thread.pause`.
		private def pause
			@pause_counter += 1
			if ! @is_paused
				@is_paused = true
				@pause_listeners.each &.call
			end
		end
		# :ditto:
		private def resume
			@pause_counter -= 1
			if @pause_counter < 1
				@pause_counter = 0
				@is_paused = false
				@resume_listeners.each &.call
			end
		end
		# :ditto:
		def pause(&block)
			@pause_mutex.lock
			pause
			yield
			resume
			@pause_mutex.unlock
		end
		@resume_listeners = [] of Proc(Nil)
		def on_resume(&block)
			@resume_listeners << block
		end
		@suspend_listeners = [] of Proc(Nil)
		def on_suspend(&block)
			@suspend_listeners << block
		end
		getter suspended = false
		def suspend
			@suspended = true
			@suspend_listeners.each &.call
		end
		@unsuspend_listeners = [] of Proc(Nil)
		def on_unsuspend(&block)
			@unsuspend_listeners << block
		end
		def unsuspend
			@suspended = false
			@unsuspend_listeners.each &.call
		end

		private def handle_event(key_event, keysym)
			{% if ! flag?(:release) %}
				puts "[debug] key event key:#{key_event.key_name}, text:#{key_event.text}, sym:#{keysym}, modifiers:#{key_event.modifiers}, up:#{key_event.up}, down:#{key_event.down}, repeat:#{key_event.repeat}"
			{% end %}
			@key_listeners.each do |sub|
				spawn same_thread: true do
					sub.call(key_event, keysym, @is_paused)
				end
			end
		end
		@key_listeners = [] of Proc(KeyCombination, UInt64, Bool, Nil)
		def register_key_listener(&block : KeyCombination, UInt64, Bool -> _)
			@key_listeners << block
			block
		end
		def unregister_key_listener(proc)
			@key_listeners.reject! &.== proc
		end

		def at_spi(&block : AtSpi -> T) forall T
			# AtSpi stuff can fail in various ways with null pointers, (rare) crashes, timeouts etc.
			# so this is some kind of catch-all method which seems to work great
			error = nil
			5.times do |i|
				begin
					resp : T? = nil
					@gtk.act do # to make use of the GC mgm
						resp = block.call @at_spi
					end
					return resp
				rescue e
					error = e
					STDERR.puts "An internal AtSpi request failed. Retrying... (#{i+1}/5)"
					sleep 600.milliseconds
				end
			end
			STDERR.puts "AtSpi failed five times in a row. Last seen error:"
			error.not_nil!.inspect_with_backtrace(STDERR)
			return nil
		end
	end
end