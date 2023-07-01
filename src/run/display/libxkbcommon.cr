# This file was copied over from https://github.com/nickbclifford/gkeybind

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

require "evdev"

lib LibXKBCommon
	struct RuleNames
		rules : LibC::Char*
		model : LibC::Char*
		layout : LibC::Char*
		variant : LibC::Char*
		options : LibC::Char*
	end

	enum KeyDirection
		Up	 = 0
		Down = 1
	end

	enum ContextFlags
		NoFlags				= 0
		NoDefaultIncludes	= 1
		NoEnvironmentNames	= 2
	end

	enum KeymapCompileFlags
		NoFlags = 0
	end

	enum KeymapFormat
		TextV1 = 1
	end

	enum KeysymFlags
		NoFlags			= 0
		CaseInsensitive = 1
	end

	type Context = Void*
	type Keymap = Void*
	type State = Void*

	alias KeymapIterT = (Keymap, UInt32, Void* -> Void)
	alias KeysymT = UInt32

	fun context_new = xkb_context_new(flags : ContextFlags) : Context
	fun context_free = xkb_context_unref(context : Context)
	fun keymap_new_names = xkb_keymap_new_from_names(context : Context, names : RuleNames*, flags : KeymapCompileFlags) : Keymap
	fun keymap_new_string = xkb_keymap_new_from_string(context : Context, string : LibC::Char*, format : KeymapFormat, flags : KeymapCompileFlags) : Keymap
	fun keymap_for_each = xkb_keymap_key_for_each(keymap : Keymap, iter : KeymapIterT, data : Void*)
	fun keymap_free = xkb_keymap_unref(keymap : Keymap)
	fun keysym_from_name = xkb_keysym_from_name(name : LibC::Char*, flags : KeysymFlags) : KeysymT
	fun state_new = xkb_state_new(keymap : Keymap) : State
	fun state_free = xkb_state_unref(state : State)
	fun state_key_get_sym = xkb_state_key_get_one_sym(state : State, key : UInt32) : KeysymT
	fun state_update_key = xkb_state_update_key(state : State, key : UInt32, direction : KeyDirection)
	fun utf32_to_keysym = xkb_utf32_to_keysym(ucs : UInt32) : KeysymT
	fun keysym_to_utf32 = xkb_keysym_to_utf32(sym : KeysymT) : UInt32
end