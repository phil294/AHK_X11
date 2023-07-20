# SoundGet, OutputVar [, ComponentType, ControlType, DeviceNumber]
class Cmd::Misc::SoundGet < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 4 end
	def self.sets_error_level; true end
	def run(thread, args)
		out_var = args[0]
		on_off = args[2] && ["onoff","mute"].includes?(args[2].downcase)
		if on_off
			is_on = `amixer get Master | tail -2 | grep -c '\\[on\\]'`.strip != "0"
			if args[2].downcase == "mute"
				is_on = ! is_on
			end
			value = is_on ? "ON" : "OFF"
		else
			value = `awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master)`.strip.[...-1]
		end
		thread.runner.set_user_var(out_var, value)
		"0"
	end
end