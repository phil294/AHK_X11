require "x_do"
require "./display/x11"
require "./display/hotstrings"
require "./display/hotkeys"
require "./display/pressed-keys"
require "./display/gui"
require "./display/at-spi"

module Run
	# Groups all modules that require a running display server.
	class Display
		getter adapter : DisplayAdapter
		getter x_do : XDo
		getter gui : Gui
		getter hotstrings : Hotstrings
		getter hotkeys : Hotkeys
		getter pressed_keys : PressedKeys
		@runner : Runner

		def initialize(@runner)
			@adapter = X11.new
			@gui = Gui.new default_title: (@runner.get_global_var("A_ScriptName") || "")
			@at_spi = AtSpi.new
			@x_do = XDo.new
			@hotstrings = Hotstrings.new(@runner, @runner.settings.hotstring_end_chars)
			@hotkeys = Hotkeys.new(@runner)
			@pressed_keys = PressedKeys.new(@runner)
		end

		def run(*, hotstrings, hotkeys)
			spawn do
				@adapter.run key_handler: ->handle_event(::X11::KeyEvent, UInt64, Char?)
			end
			@hotstrings.run
			hotstrings.each { |h| @hotstrings.add h }
			@hotkeys.run
			hotkeys.each { |h| @hotkeys.add h }
			@pressed_keys.run
			# Cannot use normal mt `spawn` because https://github.com/crystal-lang/crystal/issues/12392
			::Thread.new do
				gui.run # separate worker thread because gtk loop is blocking
			end
			gui.init(@runner)
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

		# TODO: put keysym and char into key_event in callers?
		private def handle_event(key_event, keysym, char)
			return if @is_paused
			@key_listeners.each do |sub|
				sub.call(key_event, keysym, char)
			end
		end
		@key_listeners = [] of Proc(::X11::KeyEvent, UInt64, Char?, Nil)
		def register_key_listener(&block : ::X11::KeyEvent, UInt64, Char? -> _)
			@key_listeners << block
			block
		end
		def unregister_key_listener(proc)
			@key_listeners.reject! &.== proc
		end

		def at_spi
			# AtSpi stuff can fail in various ways with null pointers, (rare) crashes, timeouts etc.
			# so this is some kind of catch-all method which seems to work great
			GC.disable
			error = nil
			5.times do |i|
				begin
					resp = yield @at_spi
					GC.enable
					GC.collect
					return resp
				rescue e : Run::RuntimeException
					GC.enable
					GC.collect
					raise e
				rescue e
					e.inspect_with_backtrace(STDERR)
					error = e
					sleep 250.milliseconds
					STDERR.puts "Retrying... (#{i+1}/5)"
				end
			end
			GC.enable
			GC.collect
			raise error.not_nil!
		end
	end
end