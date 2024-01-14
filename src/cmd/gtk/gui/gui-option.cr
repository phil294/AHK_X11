class Cmd::Gtk::Gui::GuiOption < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def run(thread, args)
		gui_id = args[0]
		opt = thread.parse_word_options(args[1])
		if opt[""]?.try &.[:n] == 0x80000000 # WS_POPUP
			# This special option is only available at window creation time, so it needs to be configured
			# *before* the `gtk.gui()` call is made where the window will be created and this setting
			# should be respected. Consequently, this option can have no effect once any other gui command ran.
			thread.runner.display.gtk.guis_creation_info[gui_id] ||= Run::Gtk::GuiCreationInfo.new(type: ::Gtk::WindowType::Popup)
		end
		thread.runner.display.gtk.gui(thread, gui_id) do |gui|
			opt.each do |w, i|
				case w
				when "caption" then gui.window.decorated = ! i[:minus]
				when "resize" then gui.window.resizable = ! i[:minus]
				when "maximizebox", "minimizebox"
					gui.window.type_hint = i[:minus] ?
						::Gdk::WindowTypeHint::Menu :
						::Gdk::WindowTypeHint::Normal
				when "toolwindow" then gui.window.skip_taskbar_hint = ! i[:minus]
				# FIXME: https://github.com/phil294/vimium-everywhere/issues/3
				# type_hint: ::Gdk::WindowTypeHint::Tooltip, accept_focus: false, can_focus: false
				# ^ ?ka

				# https://learn.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
				# (with current parser, only one ext window style can be passed in the same invocation)
				when "e"
					case i[:n]
					when 0x8000000 # WS_EX_NOACTIVATE
						# These actually don't seem to do anything on X11 but perhaps necessary on Wayland?
						gui.window.accept_focus = i[:minus]
						gui.window.can_focus = i[:minus]
						# Not sure about this one and it probably doesn't even belong into this style:
						# gui.window.type_hint = i[:minus] ? ::Gdk::WindowTypeHint::Normal : ::Gdk::WindowTypeHint::Tooltip
					end
				# https://learn.microsoft.com/en-us/windows/win32/winmsg/window-styles
				# (with current parser, only one window style can be passed in the same invocation)
				when ""
					# case i[:n]
					# when 0x80000000 # WS_POPUP
					# (moved above)
				end
			end
		end
	end
end