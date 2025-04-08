require "compiler/crystal/ffi"
require "compiler/crystal/loader"
require "../../util/ahk-bin-var.cr"

# AHK_X11 only / is a function in win ahk1.1+
# DllCall, OutputVar, [DllFile\]Function [, Type1, Arg1Var, Type2, Arg2Var, ReturnType]
# Any param and return value that isn't of type `Ptr` is eventually stored as a serialized String again, e.g.
# ret=1_u64 becomes user_var=ret.to_s.to_slice == [49]\0. This means that there is a lot of
# conversion going on which isn't optimal but necessary due to ahkx11's string-only vars.
class Cmd::Misc::DllCall < Cmd::Base
	@@loader = Crystal::Loader.new(Crystal::Loader.default_search_paths)

	def self.min_args; 2 end
	def self.max_args; 999 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var = args[0]
		lib_str = args[1]
		params = [] of TypedParam
		((args.size - 2) / 2).to_i.times do |i|
			var_type = args[i * 2 + 2].downcase
			var_name = args[i * 2 + 3].downcase
			user_var = thread.runner.get_user_var(var_name)
			return "-2" if user_var.nil?

			param = TypedParam.new(var_name: var_name, type_str: var_type, slice: user_var)
			as_type = Util::AhkBinVar.str_to_type(param.slice, param.type)
			if param.slice.read_only? || as_type.size > param.slice.size
				# Crystal Strings consist of a readonly slice plus a \0 nul byte that isn't part of the slice.
				# So when creating a new writeable slice here the zero terminating byte needs to be added again.
				tmp = Bytes.new(as_type.size + 1) # [-1]==0_u8
				param.slice = Bytes.new(tmp.to_unsafe, as_type.size)
			end
			param.slice.copy_from(as_type)
			if param.slice.to_unsafe.address != user_var.to_unsafe.address
				user_var = param.slice
				thread.runner.set_user_var(var_name, user_var)
			end
			params << param
		end
		return_type_str = "int"
		if args.size - params.size * 2 - 2 == 1
			return_type_str = args.last.downcase
		end
		return_param = TypedParam.new(var_name: out_var, type_str: return_type_str, slice: Bytes.new(8, 48_u8)) # 48 == "0"

		split = lib_str.split(/[\\\/]/)
		return "-3" if split.size < 2
		function_name = split[-1]
		library = split[...-1].join("/")
		if ! @@loader.loaded_libraries.includes? library
			loaded = @@loader.load_library? library
			if ! loaded
				# return "-3"
				raise Crystal::Loader::LoadError.new_dl_error "cannot load '#{library}'"
			end
		end

		call_interface = Crystal::FFI::CallInterface.new return_param.type, params.map &.type
		function_pointer = @@loader.find_symbol?(function_name)
		return "-4" if ! function_pointer
		arg_pointers = params.map do |param|
			if param.as_pointer
				Pointer(UInt64).malloc(1, param.slice.to_unsafe.address).as(Pointer(Void))
			else
				param.slice.to_unsafe.as(Pointer(Void))
			end
		end
		call_interface.call(function_pointer, arg_pointers.to_unsafe, return_param.slice.to_unsafe.as(Pointer(Void)))

		params << return_param
		params.each do |param|
			user_var = Util::AhkBinVar.type_to_str(param.slice, param.type)
			thread.runner.set_user_var(param.var_name, user_var)
		end
		"0"
	end

	class TypedParam
		getter type : Util::AhkBinVar::Type
		getter as_pointer : Bool
		property slice : Bytes
		getter var_name : ::String
		# Modifies *slice* and/or sets a new one if too small or not writable
		def initialize(*, var_name : ::String, type_str : ::String, slice : Bytes)
			@slice = slice
			@as_pointer = type_str.ends_with?("p") || type_str.ends_with?("*")
			@var_name = var_name
			type_str = type_str[...-1] if @as_pointer
			@as_pointer = true if type_str == "str"
			@type = Util::AhkBinVar.parse_type type_str
		end
	end
end