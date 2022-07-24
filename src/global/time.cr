struct Time # extending because this is ahk std lib
	def to_YYYYMMDDHH24MISS
		to_s("%Y%m%d%H%M%S")
	end
	def self.parse_YYYYMMDDHH24MISS?(str)
		int = str.to_i?(strict: true)
		return nil if str.size > 14 || int.nil? || int < 1601
		add = "yyyy0101000000"[str.size..]
		str += "yyyy0101000000"[str.size..]
		begin
			return parse(str, "%Y%m%d%H%M%S", Time::Location.local)
		rescue e
			pp! e
			return nil
		end
	end
end