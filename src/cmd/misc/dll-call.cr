require "compiler/crystal/ffi"
require "compiler/crystal/loader"

# AHK_X11 only / is a function in win ahk1.1+
# DllCall, OutputVar, [DllFile\]Function [, Type1, Arg1Var, Type2, Arg2Var, ReturnType]
class Cmd::Misc::DllCall < Cmd::Base
	@@loader = Crystal::Loader.new(Crystal::Loader.default_search_paths)

	def self.min_args; 2 end
	def self.max_args; 999 end
	def self.sets_error_level; true end
	def run(thread, args)
		# GC.disable
		out_var = args[0]
		lib_str = args[1]
		params = [] of TypedParam
		((args.size - 2) / 2).to_i.times do |i|
			var_type = args[i * 2 + 2].downcase
			var_name = args[i * 2 + 3].downcase
			user_var = thread.runner.get_user_var(var_name)
			return "-2" if user_var.nil?

			p! user_var
			param = TypedParam.new(type_str: var_type, slice: user_var, transform_memory: true)
			if param.slice.to_unsafe.address != user_var.to_unsafe.address
				user_var = param.slice
				thread.runner.set_user_var(var_name, user_var)
			end
			p! user_var, param.value_as_user_var
			return "-2" if param.type == Crystal::FFI::Type.void
			params << param
		end
		return_type_str = "int"
		if args.size - params.size * 2 - 2 == 1
			return_type_str = args.last.downcase
		end
		return_param = TypedParam.new(type_str: return_type_str, slice: Bytes.new(8, 48_u8), transform_memory: false) # 48 == "0"
		return "-2" if return_param.type == Crystal::FFI::Type.void

		# TODO: fails for deep paths
		split = lib_str.split(/[\\\/]/)
		return "-3" if split.size != 2
		library = split[0]
		function_name = split[1]
		if ! @@loader.loaded_libraries.includes? library
			loaded = @@loader.load_library? library
			return "-3" if ! loaded
		end

		call_interface = Crystal::FFI::CallInterface.new return_param.type, params.map &.type
		function_pointer = @@loader.find_symbol?(function_name)
		return "-4" if ! function_pointer
		arg_pointers = params.map do |param|
			# TODO:
			# if param.as_pointer
			# 	tmp_ptr = pointerof(tmp_var)
			# 	pointerof(tmp_ptr).as(Pointer(Void))
			# else
			p! param.slice, param.slice.hexdump
			p! Bytes.new(param.slice.to_unsafe, 10)
			if param.type_str == "str" # < unify with as_pointer somehow?
				# TODO: othe rnotation using pointer.new etc?
				addr = param.slice.to_unsafe.address
				pointerof(addr).as(Pointer(Void))
			else
				param.slice.to_unsafe.as(Pointer(Void))
			end
		end
		call_interface.call(function_pointer, arg_pointers.to_unsafe, return_param.slice.to_unsafe.as(Pointer(Void)))
		typed_return_value = return_param.value_as_user_var
		thread.runner.set_user_var(out_var, typed_return_value)
		"0"
	end

	class TypedParam
		getter type : Crystal::FFI::Type
		getter type_str : ::String
		getter as_pointer : Bool
		getter slice : Bytes
		# Modifies *slice* and/or sets a new one if too small or not writable
		def initialize(*, type_str : ::String, slice : Bytes, transform_memory = false)
			@slice = slice
			@as_pointer = type_str.ends_with?("p") || type_str.ends_with?("*")
			type_str = type_str[..-1] if @as_pointer
			@type_str = type_str
			if type_str == "ptr"
				return @type = Crystal::FFI::Type.sint64
			end
			as_string = ::String.new(@slice)
			@type = Crystal::FFI::Type.void
			case type_str
				# Need separate helper vars to take the pointer from because if it's a unified one,
				# the union type has an unpredictable(?) length and copying fails
				# TODO: ^v revise
				when "str" then @type = Crystal::FFI::Type.pointer; as_type = Bytes.new(@slice.to_unsafe, @slice.size + 1) # + \0. # TODO: revert
				when "int64" then @type = Crystal::FFI::Type.sint64; v_int64 = as_string.to_i64; as_type = Bytes.new(pointerof(v_int64).as(Pointer(UInt8)), 8)
				when "int" then @type = Crystal::FFI::Type.sint32; v_int = as_string.to_i32; as_type = Bytes.new(pointerof(v_int).as(Pointer(UInt8)), 4)
				when "short" then @type = Crystal::FFI::Type.sint16; v_short = as_string.to_i16; as_type = Bytes.new(pointerof(v_short).as(Pointer(UInt8)), 2)
				when "char" then @type = Crystal::FFI::Type.sint8; v_char = as_string.to_i8; as_type = Bytes.new(pointerof(v_char).as(Pointer(UInt8)), 1)
				when "uint64" then @type = Crystal::FFI::Type.uint64; v_uint64 = as_string.to_u64; as_type = Bytes.new(pointerof(v_uint64).as(Pointer(UInt8)), 8)
				when "uint" then @type = Crystal::FFI::Type.uint32; v_uint = as_string.to_u32; as_type = Bytes.new(pointerof(v_uint).as(Pointer(UInt8)), 4)
				when "ushort" then @type = Crystal::FFI::Type.uint16; v_ushort = as_string.to_u16; as_type = Bytes.new(pointerof(v_ushort).as(Pointer(UInt8)), 2)
				when "uchar" then @type = Crystal::FFI::Type.uint8; v_uchar = as_string.to_u8; as_type = Bytes.new(pointerof(v_uchar).as(Pointer(UInt8)), 1)
				when "float" then @type = Crystal::FFI::Type.float; v_float = as_string.to_f32; as_type = Bytes.new(pointerof(v_float).as(Pointer(UInt8)), 4)
				when "double" then @type = Crystal::FFI::Type.double; v_double = as_string.to_f64; as_type = Bytes.new(pointerof(v_double).as(Pointer(UInt8)), 8)
			end
			if transform_memory && ! as_type.nil?
				if as_type.size > @slice.size
					p! "#### extending to new slice(8) because too smol beforehand", as_type.size, @slice.size, as_string, @type_str
					@slice = Bytes.new(8)
				elsif @slice.read_only?
					p! "~~~ slice readonly, duping", as_string, @type_str
					@slice = @slice.dup
				end
				# p! "before", value, @slice, @slice.to_unsafe, @slice.to_unsafe.address, @slice.to_unsafe.value.unsafe_as(Float64), Slice.new(@slice.to_unsafe.as(Pointer(UInt8)), 8).hexdump, @slice.hexdump, @slice.size, type, as_type.unsafe_as(Float64), Slice.new(pointerof(as_type).as(Pointer(UInt8)), 16).hexdump, sizeof(typeof(as_type)), sizeof(Float64)
				@slice.copy_from(as_type)
				# p! value, type, as_type, @slice, @slice.to_unsafe.value.unsafe_as(Float64), Slice.new(@slice.to_unsafe.as(Pointer(UInt8)), 8).hexdump, @slice.hexdump, @slice.size
			end
		end
		def value_as_user_var
			# TODO: there's probably a better way. also using as(typeof())?
			formatted = case @type_str
				when "str" then @slice
				# TODO: unify all types)
				# There doesn't seem to be a Int::to_s_bytes method so this string instantiation takes place
				# unnecessarily (because follow-up dllcalls need to make a writable .dup again).
				when "int64" then @slice.unsafe_as(Slice(Int64)).to_unsafe.value.to_s.to_slice
				when "ptr" then
					# TODO: change to return @slice
					ptr = Pointer(UInt64).new(@slice.to_unsafe.address)
					puts "got pointer: #{ptr.value}"
					Bytes.new(ptr.unsafe_as(Pointer(UInt8)), 8)
				when "int" then @slice.unsafe_as(Slice(Int32)).to_unsafe.value.to_s.to_slice
				when "short" then @slice.unsafe_as(Slice(Int16)).to_unsafe.value.to_s.to_slice
				when "char" then @slice.unsafe_as(Slice(Int8)).to_unsafe.value.to_s.to_slice
				when "uint64" then @slice.unsafe_as(Slice(UInt64)).to_unsafe.value.to_s.to_slice
				when "uint" then @slice.unsafe_as(Slice(UInt32)).to_unsafe.value.to_s.to_slice
				when "ushort" then @slice.unsafe_as(Slice(UInt16)).to_unsafe.value.to_s.to_slice
				when "uchar" then @slice.unsafe_as(Slice(UInt8)).to_unsafe.value.to_s.to_slice
				when "float" then @slice.unsafe_as(Slice(Float32)).to_unsafe.value.to_s.to_slice
				when "double" then @slice.unsafe_as(Slice(Float64)).to_unsafe.value.to_s.to_slice
			end
			raise "?????" if ! formatted
			# if @as_pointer
			# 	# TODO: this cant work, needs to come first / like "ptr". also should be slice not ptr
			# 	return Pointer(Void).new(Pointer(UInt64).new(addr).value).value
			# else
				return formatted
			# end
		end
	end
end