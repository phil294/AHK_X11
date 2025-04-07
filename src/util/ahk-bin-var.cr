class Util::AhkBinVar
	alias Type = Crystal::FFI::Type
	def self.parse_type(type_str : ::String) : Type
		case type_str
			# TODO: macro. tried to make one that encompasses all repetitions in the file but this didn't work with switch case, dynamic class, and the to_X methods at all.
			when "ptr", "uptr", "str" then return Type.pointer
			when "int64" then return Type.sint64
			when "int" then return Type.sint32
			when "short" then return Type.sint16
			when "char" then return Type.sint8
			when "uint64" then return Type.uint64
			when "uint" then return Type.uint32
			when "ushort" then return Type.uint16
			when "uchar" then return Type.uint8
			when "float" then return Type.float
			when "double" then return Type.double
			else raise "Invalid binary var type '#{type_str}'!"
		end
	end
	# In and out: force-casted as Bytes (Slice(UInt8)). Out: Heap
	def self.str_to_type(str : Bytes, type : Type) : Bytes
		as_string = ::String.new(str)
		case type
			when Type.pointer then return str
			when Type.sint64 then return Bytes.new(Slice(Int64).new(1, as_string.to_i64).to_unsafe.as(Pointer(UInt8)), sizeof(Int64))
			when Type.sint32 then return Bytes.new(Slice(Int32).new(1, as_string.to_i32).to_unsafe.as(Pointer(UInt8)), sizeof(Int32))
			when Type.sint16 then return Bytes.new(Slice(Int16).new(1, as_string.to_i16).to_unsafe.as(Pointer(UInt8)), sizeof(Int16))
			when Type.sint8 then return Bytes.new(Slice(Int8).new(1, as_string.to_i8).to_unsafe.as(Pointer(UInt8)), sizeof(Int8))
			when Type.uint64 then return Bytes.new(Slice(UInt64).new(1, as_string.to_u64).to_unsafe.as(Pointer(UInt8)), sizeof(UInt64))
			when Type.uint32 then return Bytes.new(Slice(UInt32).new(1, as_string.to_u32).to_unsafe.as(Pointer(UInt8)), sizeof(UInt32))
			when Type.uint16 then return Bytes.new(Slice(UInt16).new(1, as_string.to_u16).to_unsafe.as(Pointer(UInt8)), sizeof(UInt16))
			when Type.uint8 then return Bytes.new(Slice(UInt8).new(1, as_string.to_u8).to_unsafe.as(Pointer(UInt8)), sizeof(UInt8))
			when Type.float then return Bytes.new(Slice(Float32).new(1, as_string.to_f32).to_unsafe.as(Pointer(UInt8)), sizeof(Float32))
			when Type.double then return Bytes.new(Slice(Float64).new(1, as_string.to_f64).to_unsafe.as(Pointer(UInt8)), sizeof(Float64))
			else raise "Invalid binary var type '#{type}'"
		end
	end
	# :ditto:
	def self.type_to_str(bytes : Bytes, type : Type) : Bytes
		case type
			when Type.pointer then return bytes
			when Type.uint64 then return bytes.unsafe_as(Slice(Int64)).to_unsafe.value.to_s.to_slice
			when Type.sint32 then return bytes.unsafe_as(Slice(Int32)).to_unsafe.value.to_s.to_slice
			when Type.sint16 then return bytes.unsafe_as(Slice(Int16)).to_unsafe.value.to_s.to_slice
			when Type.sint8 then return bytes.unsafe_as(Slice(Int8)).to_unsafe.value.to_s.to_slice
			when Type.uint64 then return bytes.unsafe_as(Slice(UInt64)).to_unsafe.value.to_s.to_slice
			when Type.uint32 then return bytes.unsafe_as(Slice(UInt32)).to_unsafe.value.to_s.to_slice
			when Type.uint16 then return bytes.unsafe_as(Slice(UInt16)).to_unsafe.value.to_s.to_slice
			when Type.uint8 then return bytes.unsafe_as(Slice(UInt8)).to_unsafe.value.to_s.to_slice
			when Type.float then return bytes.unsafe_as(Slice(Float32)).to_unsafe.value.to_s.to_slice
			when Type.double then return bytes.unsafe_as(Slice(Float64)).to_unsafe.value.to_s.to_slice
			else raise "Invalid binary var type #{type}!"
		end
	end
end