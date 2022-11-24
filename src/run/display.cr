require "./x11"
require "x_do"
require "./hotstrings"
require "./hotkeys"
require "./gui"
require "./at-spi"

module Run
	# Groups all modules that require a running display server.
	class Display
		getter adapter : DisplayAdapter
		getter x_do : XDo
		getter gui : Gui
		getter at_spi : AtSpi
		getter hotstrings : Hotstrings
		getter hotkeys : Hotkeys
		@runner : Runner

		def initialize(@runner)
			@adapter = X11.new
			@gui = Gui.new default_title: (@runner.get_global_var("A_ScriptName") || "")
			@at_spi = AtSpi.new
			@x_do = XDo.new
			@hotstrings = Hotstrings.new(@runner, @runner.settings.hotstring_end_chars)
			@hotkeys = Hotkeys.new(@runner)
		end

		def run(*, hotstrings, hotkeys)
			spawn do
				@adapter.run key_handler: ->handle_event(::X11::KeyEvent, UInt64, Char?)
			end
			@hotstrings.run
			hotstrings.each { |h| @hotstrings.add h }
			@hotkeys.run
			hotkeys.each { |h| @hotkeys.add h }
			# Cannot use normal mt `spawn` because https://github.com/crystal-lang/crystal/issues/12392
			::Thread.new do
				gui.run # separate worker thread because gtk loop is blocking
			end
			gui.initialize_menu(@runner)
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
		def pause
			@pause_mutex.lock
			@pause_counter += 1
			if ! @is_paused
				@is_paused = true
				@pause_listeners.each &.call
			end
			@pause_mutex.unlock
		end
		@resume_listeners = [] of Proc(Nil)
		def on_resume(&block)
			@resume_listeners << block
		end
		# :ditto:
		def resume
			@pause_mutex.lock
			@pause_counter -= 1
			if @pause_counter < 1
				@pause_counter = 0
				@is_paused = false
				@resume_listeners.each &.call
			end
			@pause_mutex.unlock
		end
		# :ditto:
		def pause(&block)
			pause
			yield
			resume
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

		@pressed_down_keysyms : StaticArray(UInt64, 8) = StaticArray[0_u64,0_u64,0_u64,0_u64,0_u64,0_u64,0_u64,0_u64]

		# TODO: put keysym and char into key_event in callers?
		private def handle_event(key_event, keysym, char)
			return if @is_paused
			up = key_event.type == ::X11::KeyRelease || key_event.type == ::X11::ButtonRelease

			if ! up
				free_slot = @pressed_down_keysyms.index(keysym) || @pressed_down_keysyms.index(0)
				@pressed_down_keysyms[free_slot] = keysym if free_slot
			else
				pressed_slot = @pressed_down_keysyms.index(keysym)
				@pressed_down_keysyms[pressed_slot] = 0_u64 if pressed_slot
			end

			@key_listeners.each do |sub|
				sub.call(key_event, keysym, char)
			end
		end
		@key_listeners = [] of Proc(::X11::KeyEvent, UInt64, Char?, Nil)
		def register_key_listener(&block : ::X11::KeyEvent, UInt64, Char? -> _)
			@key_listeners << block
		end
		def unregister_key_listener(&block)
			@key_listeners.reject! &.== block
		end

		def keysym_pressed_down?(keysym)
			!! @pressed_down_keysyms.index(keysym)
		end
	end
end