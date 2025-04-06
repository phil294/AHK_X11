# AHK_X11 only / is a function in win ahk1.1+
# VarSetCapacity, GrantedCapacity, TargetVar [, RequestedCapacity, FillByte]
class Cmd::Misc::VarSetCapacity < Cmd::Base
	@@loader = Crystal::Loader.new(Crystal::Loader.default_search_paths)

	def self.min_args; 2 end
	def self.max_args; 4 end
	def run(thread, args)
		out_var = args[0]
		target_var = thread.runner.get_user_var(args[1])
		req_capacity = args[2]?.try &.to_i
		if !req_capacity
			return thread.runner.set_user_var(out_var, target_var ? target_var.size.to_s : "0")
		end
		fill_byte = (args[3]?.try &.to_u8) || 0_u8
		new_var = Bytes.new(req_capacity, fill_byte)
		thread.runner.set_user_var(args[1], new_var)
		thread.runner.set_user_var(out_var, req_capacity.to_s)
	end
end