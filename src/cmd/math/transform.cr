
require "math"
require "../../util/ahk-string"

class Cmd::Math::Transform < Cmd::Base
	def self.min_args; 3 end
	def self.max_args; 4 end

	def run(thread, args)
		output_var, cmd, value1, *_ = args
		value2 = args[3]?
		result = ""
		case cmd.downcase
		when "unicode"
			raise ::Run::RuntimeException.new "Unimplemented 'Transform' command."
		when "asc"
			result = value1.codepoint_at(0).to_s if value1 != ""
		when "chr"
			result = value1.to_i32(whitespace: false, prefix: true).chr.to_s rescue ""
		when "deref"
			result = Util::AhkString.parse_string(value1, thread.runner.settings.escape_char) do |var_name_lookup|
				thread.get_var(var_name_lookup)
			end
		when "html"
			raise ::Run::RuntimeException.new "Unimplemented 'Transform' command."
		when "mod"
			value1 = value1.to_i64(whitespace: false, prefix: true)
			value2 = args[3].to_i64(whitespace: false, prefix: true)
			result = (value1 % value2).to_s if value2 != 0
		when "pow"
			value1 = value1.to_f64
			value2 = args[3].to_f64
			result = (value1 ** value2).to_s
		when "exp"
			value1 = value1.to_f64
			result = ::Math.exp(value1).to_s
		when "sqrt"
			value1 = value1.to_f64
			result = ::Math.sqrt(value1).to_s if value1 >= 0.0
		when "log"
			value1 = value1.to_f64
			result = ::Math.log10(value1).to_s if value1 > 0.0
		when "ln"
			value1 = value1.to_f64
			result = ::Math.log(value1).to_s if value1 > 0.0
		when "round"
			value1 = value1.to_f64
			digits = (value2 || "0").to_i
			result = value1.round(digits)
			result = result.to_i if digits <= 0
			result = result.to_s
		when "ceil"
			value1 = value1.to_f64
			result = value1.ceil.to_i.to_s
		when "floor"
			value1 = value1.to_f64
			result = value1.floor.to_i.to_s
		when "abs"
			result = value1
			result = value1[1..] if value1[0, 1] == "-"
		when "sin"
			value1 = value1.to_f64
			result = ::Math.sin(value1).to_s
		when "cos"
			value1 = value1.to_f64
			result = ::Math.cos(value1).to_s
		when "tan"
			value1 = value1.to_f64
			result = ::Math.tan(value1).to_s
		when "asin"
			value1 = value1.to_f64
			result = ::Math.asin(value1).to_s if value1 >= -1.0 && value1 <= 1.0
		when "acos"
			value1 = value1.to_f64
			result = ::Math.acos(value1).to_s if value1 >= -1.0 && value1 <= 1.0
		when "atan"
			value1 = value1.to_f64
			result = ::Math.atan(value1).to_s
		when "bitnot"
			value1 = value1.to_i64(whitespace: false, prefix: true)
			value1 = value1.to_u32 if 0 <= value1 && value1 <= 0xffffffff
			result = (~value1).to_s
		when "bitand"
			value1 = value1.to_i64(whitespace: false, prefix: true)
			value2 = args[3].to_i64(whitespace: false, prefix: true)
			result = (value1 & value2).to_s
		when "bitor"
			value1 = value1.to_i64(whitespace: false, prefix: true)
			value2 = args[3].to_i64(whitespace: false, prefix: true)
			result = (value1 | value2).to_s
		when "bitxor"
			value1 = value1.to_i64(whitespace: false, prefix: true)
			value2 = args[3].to_i64(whitespace: false, prefix: true)
			result = (value1 ^ value2).to_s
		when "bitshiftleft"
			value1 = value1.to_i64(whitespace: false, prefix: true)
			value2 = args[3].to_i64(whitespace: false, prefix: true)
			result = (value1 << value2).to_s
		when "bitshiftright"
			value1 = value1.to_i64(whitespace: false, prefix: true)
			value2 = args[3].to_i64(whitespace: false, prefix: true)
			result = (value1 >> value2).to_s
		else
			raise ::Run::RuntimeException.new "Unrecognised 'Transform' command."
		end
		thread.runner.set_user_var output_var, result
	end
end
