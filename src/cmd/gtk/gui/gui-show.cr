# Show [, Options, Title]
class Cmd::Gtk::Gui::GuiShow < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def run(thread, args)
		gui_id = args[0]
		options = args[1]? || ""
		title = args[2]?
		thread.runner.display.gui.gui(thread, gui_id) do |gui|
			gui.window.title = title if title
			gui.window.show_all
			w, h = gui.window.size
			x, y = gui.window.position
			thread.parse_word_options(options).each do |v, i|
				n = i[:n]
				case v
				when "w" then w = n if n
				when "h" then h = n if n
				when "x" then x = n if n
				when "y" then y = n if n
				end
			end
			gui.window.set_default_size w, h
			gui.window.move x, y
		end
	end
end