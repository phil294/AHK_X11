require "../base"

class Cmd::ControlFlow::Hotkey < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 3 end
	def run(thread, args)
		key_name = args[0]
		label_arg = args[1]?
		options = args[2]? || ""

		active_state = nil
		label = nil

		if label_arg
			label_arg = label_arg.downcase
			case label_arg
			when "on" then active_state = true
			when "off" then active_state = false
			else label = label_arg end
		end

		buffer = false # TODO: not used
		priority = 0
		max_threads = nil # TODO: not used
		thread.parse_letter_options options do |char, n|
			case char
			when 'B' then buffer = n == 0
			when 'P' then priority = n || 0
			when 'T' then max_threads = n
			end
		end
		
		thread.runner.add_or_update_hotkey label: label, key_str: key_name, priority: priority, active_state: active_state
	end
end