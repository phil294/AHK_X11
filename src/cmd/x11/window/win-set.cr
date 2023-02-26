require "./win-util"
# WinSet, Attribute, Value [, WinTitle, WinText, ExcludeTitle, ExcludeText]
class Cmd::X11::Window::WinSet < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 6 end
	def run(thread, args)
		sub_cmd = args[0].downcase
		value = args[1].downcase
		x11_dpy = thread.runner.display.adapter.as(Run::X11).display
		Util.match(thread, args[2..], empty_is_last_found: true, a_is_active: true) do |win|
			case sub_cmd
			when "alwaysontop"
				action = case value
				when "off" then XDo::WindowStateAction::Remove
				when "toggle" then XDo::WindowStateAction::Toggle
				else XDo::WindowStateAction::Add
				end
				win.set_state(action, "above")
			when "bottom"
				# For some reason libxdo windowlower cmd PR has not been merged:
				# https://github.com/jordansissel/xdotool/pull/108
				# so we need to run native x11
				x11_dpy.lower_window(win.window)
				x11_dpy.sync(false)
			when "transparent"
				if value == "off"
					x11_dpy.delete_property(win.window, x11_dpy.intern_atom("_NET_WM_WINDOW_OPACITY", false))
				else
					opacity_factor = (value.to_f? || 255_f64).clamp(0_f64, 255_f64) / 255
					x11_dpy.change_property(win.window, x11_dpy.intern_atom("_NET_WM_WINDOW_OPACITY", false), ::X11::C::XA_CARDINAL.to_u64, ::X11::C::PropModeReplace, Slice.new(1, (opacity_factor * 0xffffffff).to_u32.unsafe_as(Int32)))
				end
				x11_dpy.sync(false)
			when "transcolor"
				color = value.split(' ')[0].downcase
				gui = thread.runner.display.gtk.guis.find do |gui_id, gui_info|
					win.window == gui_info.window.window.unsafe_as(GdkX11::X11Window).xid
				end
				if ! gui
					raise Run::RuntimeException.new "WinSet, TransColor is only supported for your own Gui windows in order to be able to achieve transparent background. However the window you passed, '#{win.name}', does not appear to be such a Gui."
				end
				gui_id, gui_info = gui
				if ! gui_info.window_color || ! gui_info.window_color.not_nil!.equal(thread.runner.display.gtk.parse_rgba(color))
					raise Run::RuntimeException.new "WinSet, TransColor currently only works when you previously set \"Gui, Color\" to the same color."
				end
				thread.runner.display.gtk.act do
					gui_info.window.override_background_color(::Gtk::StateFlags::Normal, ::Gdk::RGBA.new(0,0,0,0))
				end
			end
		end
	end
end