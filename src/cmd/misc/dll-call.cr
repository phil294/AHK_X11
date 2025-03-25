require "compiler/crystal/ffi"
require "compiler/crystal/loader"

# ; pi = 3.14
# ; DllCall, out_var, libm.so.6/cos, Double, pi, Double
#
# ; txt = abc`n
# ; DllCall, , libc.so.6/printf, Str, txt
#
# EnvGet, display_name, DISPLAY
# DllCall, display, X11/XOpenDisplay, Str, display_name, Ptr
# if display = `0`0`0`0`0`0`0`0 ; Pointers have a length of 8 Bytes.
# {
# 	MsgBox, 48, DllCall Demo, Cannot open Display "%display_name%"!
# 	Return
# }
# DllCall, screen, X11/XDefaultScreen, Ptr, display, Ptr
# DllCall, root_window, X11/XRootWindow, Ptr, display, Ptr, screen, UInt64
# DllCall, black_pixel, X11/XBlackPixel, Ptr, display, Ptr, screen, UInt64
# DllCall, white_pixel, X11/XWhitePixel, Ptr, display, Ptr, screen, UInt64
# x = 10
# y = 10
# w = 400
# h = 700
# border_width = 20
# DllCall, window, X11/XCreateSimpleWindow, Ptr, display, UInt64, root_window, Int, x, Int, y, Int, w, Int, h, Int, border_width, UInt64, black_pixel, UInt64, white_pixel, UInt64
# gc_valuemask = 0
# gc_values = `0 ; NULL
# DllCall, gc, X11/XCreateGC, Ptr, display, UInt64, window, UInt64, gc_valuemask, Ptr, gc_values, Ptr
# DllCall, , X11/XSetForeground, Ptr, display, Ptr, gc, UInt64, black_pixel
# ExposureMask = 32768
# DllCall, , X11/XSelectInput, Ptr, display, UInt64, window, UInt64, ExposureMask
# DllCall, , X11/XMapWindow, Ptr, display, UInt64, window
# ; to do: settimer xnextevent
# ; event_type = "0"
# ; DllCall, , X11/XNextEvent, Ptr, display, Int*, event_type
# ; varsetcapacity event 10525
# ; DllCall, , X11/XNextEvent, Ptr, display, Ptr, event
# event = 1
# DllCall, , X11/XNextEvent, Ptr, display, Ptr, event
# sleep 1000

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
			return "-2" if user_var == nil
			write_memory = true
			if user_var.is_a?(Bytes)
				user_var_value = "0"
				user_var_slice = user_var
				write_memory = false
			else
				user_var_value = user_var
				# FFI below needs pointers only, that's why there's an extra Slice wrapper around all vars everywhere
				user_var_slice = Bytes.new(8) # 64b to accommodate size of any param except string TODO:
				thread.runner.set_user_var(var_name, user_var_slice)
			end
			# May mutate user_var_slice's underlying value to set up the correct type
			param = TypedParam.new(type: var_type, slice: user_var_slice, value: user_var_value.not_nil!, write_memory: write_memory)
			p! user_var_value, param.value_as_user_var, write_memory
			return "-2" if param.type == Crystal::FFI::Type.void
			params << param
		end
		return_type_str = "int"
		if args.size - params.size * 2 - 2 == 1
			return_type_str = args.last.downcase
		end
		return_param = TypedParam.new(type: return_type_str, slice: Bytes.new(8), value: "0", write_memory: false)
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
			if param.type_str == "str"
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
		# Mutates the underlying value of *slice*
		def initialize(*, type : ::String, slice : Bytes, value : ::String, write_memory = true)
			@slice = slice
			@as_pointer = type.ends_with?("p") || type.ends_with?("*")
			type = type[..-1] if @as_pointer
			@type_str = type
			@type = Crystal::FFI::Type.void
			case type
				# Need separate helper vars to take the pointer from because if it's a unified one,
				# the union type has an unpredictable(?) length and copying fails
				when "str" then @type = Crystal::FFI::Type.pointer; v_str = value.to_s; value_slice = v_str.to_slice
				when "int64" then @type = Crystal::FFI::Type.sint64; v_int64 = value.to_i64; value_slice = Bytes.new(pointerof(v_int64).as(Pointer(UInt8)), 8)
				when "ptr" then @type = Crystal::FFI::Type.sint64
				when "int" then @type = Crystal::FFI::Type.sint32; v_int = value.to_i32; value_slice = Bytes.new(pointerof(v_int).as(Pointer(UInt8)), 4)
				when "short" then @type = Crystal::FFI::Type.sint16; v_short = value.to_i16; value_slice = Bytes.new(pointerof(v_short).as(Pointer(UInt8)), 2)
				when "char" then @type = Crystal::FFI::Type.sint8; v_char = value.to_i8; value_slice = Bytes.new(pointerof(v_char).as(Pointer(UInt8)), 1)
				when "uint64" then @type = Crystal::FFI::Type.uint64; v_uint64 = value.to_u64; value_slice = Bytes.new(pointerof(v_uint64).as(Pointer(UInt8)), 8)
				when "uint" then @type = Crystal::FFI::Type.uint32; v_uint = value.to_u32; value_slice = Bytes.new(pointerof(v_uint).as(Pointer(UInt8)), 4)
				when "ushort" then @type = Crystal::FFI::Type.uint16; v_ushort = value.to_u16; value_slice = Bytes.new(pointerof(v_ushort).as(Pointer(UInt8)), 2)
				when "uchar" then @type = Crystal::FFI::Type.uint8; v_uchar = value.to_u8; value_slice = Bytes.new(pointerof(v_uchar).as(Pointer(UInt8)), 1)
				when "float" then @type = Crystal::FFI::Type.float; v_float = value.to_f32; value_slice = Bytes.new(pointerof(v_float).as(Pointer(UInt8)), 4)
				when "double" then @type = Crystal::FFI::Type.double; v_double = value.to_f64; value_slice = Bytes.new(pointerof(v_double).as(Pointer(UInt8)), 8)
			end
			if write_memory && ! value_slice.is_a?(Nil)
				# p! "before", value, @slice, @slice.to_unsafe, @slice.to_unsafe.address, @slice.to_unsafe.value.unsafe_as(Float64), Slice.new(@slice.to_unsafe.as(Pointer(UInt8)), 8).hexdump, @slice.hexdump, @slice.size, type, value_slice.unsafe_as(Float64), Slice.new(pointerof(value_slice).as(Pointer(UInt8)), 16).hexdump, sizeof(typeof(value_slice)), sizeof(Float64)
				@slice.copy_from(value_slice) # can fail with large strings TODO:
				# p! value, type, value_slice, @slice, @slice.to_unsafe.value.unsafe_as(Float64), Slice.new(@slice.to_unsafe.as(Pointer(UInt8)), 8).hexdump, @slice.hexdump, @slice.size
			end
		end
		def value_as_user_var
			addr = @slice.to_unsafe.address
			# TODO: there's probably a better way. also using as(typeof())?
			formatted = case @type_str
				when "str" then ::String.new(Pointer(UInt8).new(addr))
				when "int64" then Pointer(Int64).new(addr).value.to_s
				when "ptr" then
					ptr = Pointer(UInt64).new(addr)
					puts "got pointer: #{ptr.value}"
					Bytes.new(ptr.unsafe_as(Pointer(UInt8)), 8)
				when "int" then Pointer(Int32).new(addr).value.to_s
				when "short" then Pointer(Int16).new(addr).value.to_s
				when "char" then Pointer(Int8).new(addr).value.to_s
				when "uint64" then Pointer(UInt64).new(addr).value.to_s
				when "uint" then Pointer(UInt32).new(addr).value.to_s
				when "ushort" then Pointer(UInt16).new(addr).value.to_s
				when "uchar" then Pointer(UInt8).new(addr).value.to_s
				when "float" then Pointer(Float32).new(addr).value.to_s
				when "double" then Pointer(Float64).new(addr).value.to_s
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