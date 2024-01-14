# Sort, VarName [, Options]
class Cmd::String::Sort < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def run(thread, args)
		var = args[0]
		old_value = thread.get_var(var)
		opt = args[1]? || ""
		delimiter = '\n'
		d_index = opt.index('D')
		if d_index
			d_char = opt[d_index + 1]?
			delimiter = d_char if d_char
		end
		case_sensitive = opt.includes?('C')
		numeric = opt.includes?('N')
		p_index = opt.index('P')
		pos = 1
		if p_index
			p_char = opt[p_index + 1]?
			pos = p_char.to_i if p_char
		end
		pos -= 1
		reverse = opt.includes?('R')
		random = opt.includes?("Random")
		rand = ::Random.new
		z_option = opt.includes?('Z')
		split = old_value.split(delimiter)
		if ! z_option
			if split.last?
				if split.last.empty?
					split.pop
					split[split.size - 1] += delimiter
				end
			end
		end
		sorted = split.sort do |a, b|
			puts "sort iter"
			if random
				next rand.next_bool ? 1 : -1
			end
			if pos > 0
				a = a[pos..]? || ""
				b = b[pos..]? || ""
			end
			if numeric
				a = a.to_f
				b = b.to_f
				ret = a <=> b
			else
				if ! case_sensitive
					a = a.downcase
					b = b.downcase
				end
				ret = a <=> b
			end
			ret
		end
		if reverse
			sorted.reverse!
		end
		new_value = sorted.join(delimiter)
		thread.runner.set_user_var(var, new_value)
	end
end