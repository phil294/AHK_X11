require "./mouse-click"

# Click [, Options]
# Not part of 1.0.24!
class Cmd::X11::Mouse::Click < Cmd::X11::Mouse::MouseClick
	def self.min_args; 0 end
	def self.max_args; 1 end
	def run(thread, args)
		mouse_click_args = Array(::String).new(7){""}
		ints = [] of ::String
		(args[0]? || "").split.each do |param|
			case param.downcase
			when "l","r","left","right","m","middle","xbutton1","xbutton2","x1","x2","wheelup","wu","wheeldown","wd","wheelleft","wl","wheelright","wr"
				mouse_click_args[0] = param
			when "down","up","d","u"
				mouse_click_args[5] = param[0].to_s
			when "rel","relative"
				# TODO: this crashes ahk somehow, bug in mouse-click.cr
				mouse_click_args[6] = "r"
			else
				ints << param if param.to_i?
			end
		end
		if ints.size == 1
			mouse_click_args[3] = ints[0]
		elsif ints.size >= 2
			mouse_click_args[1] = ints[0]
			mouse_click_args[2] = ints[1]
			mouse_click_args[3] = ints[2]? || ""
		end
		parse_run(thread, mouse_click_args)
	end
end