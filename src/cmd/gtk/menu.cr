require "../base"

class Cmd::Gtk::Gui::Menu < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 5 end
	def run(thread, args)
		raise Run::RuntimeException.new "MenuName has to be TRAY" if args[0].downcase != "tray"
		thread.runner.gui.tray do |tray, tray_menu|
			case args[1].downcase
			when "add"
				name = args[2]?
				label = args[3]? || ""
				priority = (args[4]? || "")[1..]?.try &.to_i? || 0
				if ! name
					tray_menu.append ::Gtk::SeparatorMenuItem.new
				else
					label = name if label.empty?
					item = ::Gtk::MenuItem.new_with_label name
					item.on_activate do
						begin
							thread.runner.add_thread label.downcase, priority
						rescue e
							STDERR.puts e # TODO:
						end
					end
					tray_menu.append item
				end
			when "icon"
				path = args[2]? || "*"
				if path == "*"
					icon_pixbuf = default_icon_pixbuf
					thread.runner.set_global_built_in_static_var("A_IconFile", "")
				else
					begin
						icon_pixbuf = bytes_to_pixbuf ::File.new(path).getb_to_end
					rescue e
						raise Run::RuntimeException.new "Icon path not readable. (#{e.message})"
					end
					thread.runner.set_global_built_in_static_var("A_IconFile", ::File.expand_path(path))
				end
				tray.from_pixbuf = icon_pixbuf
				# TODO: how to skip this line? (so that icon_pixbuf= above already sets the one in gui because we're in `with self` here)
				thread.runner.gui.icon_pixbuf = icon_pixbuf
			when "noicon"
				thread.runner.set_global_built_in_static_var("A_IconFile", "")
				tray.from_pixbuf = nil
			when "tip"
				new_tip = args[2]? || ""
				tray.tooltip_text = new_tip
				thread.runner.set_global_built_in_static_var("A_IconTip", new_tip)
			else
				raise Run::RuntimeException.new "Unknown Menu Cmd '#{args[1]}'"
			end
		end
	end
end