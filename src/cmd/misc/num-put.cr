# AHK_X11 only / is a function in win ahk1.1+
# NumPut, Number, Var [, Offset, Type]
# NumPut, Number, Var [, Type]
class Cmd::Misc::NumPut < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
        input = args[0]
		user_var = thread.runner.get_user_var(args[1])
		return if ! user_var
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
		out_bin = Util::AhkBinVar.str_to_type(input.to_slice, type)
        (user_var + offset).copy_from(out_bin)
	end
end