class Cmd::Gtk::Gui::GuiShow < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def run(thread, args)
		gui_id = args[0]
		options = args[1]? || ""
		title = args[2]?
		thread.runner.gui.gui(gui_id) do |gui|
			gui.window.title = title if title
			gui.window.show_all
			w, h = gui.window.size
			x, y = gui.window.position
			thread.parse_word_options(options).each do |w, i|
				n = i[:n]
				case w
				when "w" then w = n if n
				when "h" then h = n if n
				when "x" then x = n if n
				when "y" then y = n if n
				end
			end
			gui.window.resize w, h
			gui.window.move x, y
		end
	end
end