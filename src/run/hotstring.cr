module Run
	class Hotstring
		property runner : Run::Runner?
		getter abbrev : String
		getter abbrev_keysyms : StaticArray(UInt32, 30) # todo alias type wherever used
		getter abbrev_size : UInt8
		property label : String
		property cmd : Cmd::Base?
		property immediate = false
		def initialize(@label, @abbrev)
			@abbrev_size = @abbrev.size.to_u8
			@abbrev_keysyms = StaticArray(UInt32, 30).new do |i|
				if i >= @abbrev_size
					0_u32
				else
					@abbrev[i].ord.to_u32
				end
			end
		end
		def keysyms_equal?(other_keysyms : StaticArray(UInt32, 30), other_size : UInt8)
			return false if other_size != @abbrev_size
			@abbrev_keysyms.each_with_index do |k, i|
				break if i >= @abbrev_size
				return false if k != other_keysyms[i]
			end
			true
		end
		def trigger
			# TODO: revise not_nil etc
			runner = @runner.not_nil!
			
			runner.pause_x11
			(@abbrev_size + (@immediate ? 0 : 1)).times do # TODO: ...
				runner.x_do.keys "BackSpace"
			end
			runner.resume_x11
			
			runner.add_thread @cmd.not_nil!, 0 # @priority
		end
	end
end