class Cmd::X11::Keyboard::GetKeyState < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 3 end
	def run(thread, args)
		out_var, key_name = args
		mode = ""
		keysym = nil
		begin
			keysym = thread.parse_key_combinations(key_name, implicit_braces: true)[0]?.try &.keysym
		rescue e : Run::RuntimeException
		end
		mode = thread.runner.x11.keysym_pressed_down?(keysym) ? "D" : "U" if keysym
		thread.runner.set_user_var(out_var, mode)
	end
end