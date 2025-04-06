# AHK_X11 only / is a function in win ahk1.1+
# NumGet, OutVar, Var [, Offset, Type]
# NumGet, OutVar, Var [, Type]
class Cmd::Misc::NumGet < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		out_var = args[0]
		mem = thread.runner.get_user_var(args[1])
		return if ! mem
		offset = 0
		type_str = "uptr"
		if args.size == 4
			offset = args[2].to_i? || 0
			type_str = args[3].downcase
		elsif args.size == 3
			as_i = args[2].to_i?
			if as_i
				offset = as_i
			else
				type_str = args[2].downcase
			end
		end
		if type_str.empty?
			type_str = "uptr"
		end
		type = Util::AhkBinVar.parse_type(type_str)
		out_str = Util::AhkBinVar.type_to_str(mem + offset, type)
		thread.runner.set_user_var(out_var, out_str)
	end
end