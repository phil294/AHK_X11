# SoundSet, NewSetting [, ComponentType, ControlType, DeviceNumber]
class Cmd::Misc::SoundSet < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 4 end
	def self.sets_error_level; true end
	def run(thread, args)
		value = args[0]
		on_off = args[2]? && ["onoff","mute"].includes?(args[2].downcase)
		if on_off
			if value.starts_with?('+') || value.starts_with?('-')
				`amixer sset Master toggle`
			else
				turn_on = value == "0"
				if args[2].downcase == "mute"
					turn_on = ! turn_on
				end
				if turn_on
					`amixer sset Master mute`
				else
					`amixer sset Master unmute`
				end
			end
		else
			if value.starts_with?('+') || value.starts_with?('-')
				sign = value[0]
				rel = value[1..]
				`amixer sset Master -- #{rel}%#{sign}`
			else
				`amixer sset Master -- #{value}%`
			end
		end
		"0"
	end
end