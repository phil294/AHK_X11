# require "evdev"

# Mostly copied over from https://github.com/nickbclifford/gkeybind.
# Thanks Nick!

# gkeybind: A Linux utility for binding custom behavior to Logitech keyboards. 
# Copyright (C) 2021 Nick Clifford
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

###
# KeyLookup is a StatefulDevice in reverse: You can use it to look up codes by char or keysym.
#
# There are evdev keysyms, evdev key codes, x11 keysyms, x11 key codes. They seem to
# not be interoperable (?). This lookup is technically driver-independent but uses the evdev ones.
###
class Run::KeyLookup < Run::StatefulDevice
	MODIFIERS = [::Evdev::Codes::Key::Leftshift, ::Evdev::Codes::Key::Rightalt] # Shift, AltGr

	@hash = {} of LibXKBCommon::KeysymT => Array(::Evdev::Codes::Key)

	def initialize(keymap : LibXKBCommon::Keymap)
		super(keymap)

		# Generate all possible modifier combinations
		(0..MODIFIERS.size).flat_map { |i| MODIFIERS.combinations(i) }.each do |mods|
			mods.each do |mod|
				# XKB keycode values are 8 more than their evdev equivalents
				LibXKBCommon.state_update_key(@state, mod + 8, LibXKBCommon::KeyDirection::Down)
			end

			iter keymap do |code|
				sym = LibXKBCommon.state_key_get_sym(@state, code)
				# Modifiers need to come first!
				@hash[sym] = [::Evdev::Codes::Key.new(code.to_i - 8)].concat(mods).reverse unless @hash[sym]?
			end

			mods.each do |mod|
				LibXKBCommon.state_update_key(@state, mod + 8, LibXKBCommon::KeyDirection::Up)
			end
		end
	end

	def char_to_evdev_keysym(char : Char)
		LibXKBCommon.utf32_to_keysym(char.ord)
	end
	def evdev_keysym_to_evdev_codes(sym : LibXKBCommon::KeysymT)
		codes = @hash[sym]?
		# This bit is specific to AHK_X11 because we want to treat mouse buttons and keyboard keys equally
		if ! codes && sym < 10
			codes = case sym
			when 1 then [ ::Evdev::Codes::Key::BtnLeft ]
			when 3 then [ ::Evdev::Codes::Key::BtnRight ]
			when 2 then [ ::Evdev::Codes::Key::BtnMiddle ]
			when 8 then [ ::Evdev::Codes::Key::BtnSide ]
			when 9 then [ ::Evdev::Codes::Key::BtnExtra ]
			else nil end
		end
		raise IndexError.new "Sym '#{sym}' not translatable to evdev" if ! codes
		codes
	end
	def char_to_evdev_codes(char : Char)
		begin
			evdev_keysym_to_evdev_codes(char_to_evdev_keysym(char))
		rescue e : IndexError
			raise e.class.new((e.message || "") + "\n#Char: #{char}")
		end
	end
end