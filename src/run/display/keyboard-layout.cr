# For details see https://github.com/espanso/espanso/issues/921
# https://github.com/phil294/libxkbcommon/blob/master/tools/interactive-wayland.c
lib LibXKBCustom
	fun wayland_get_keymap = xkb_custom_wayland_get_keymap() : LibXKBCommon::Keymap
end

class KeyboardLayout
    def self.get_keymap
		# Wayland keyboard layout determination is veeeery special:
		keymap = LibXKBCustom.wayland_get_keymap()
		{% if ! flag?(:release) %}
			puts "[debug] Evdev key lookup: Is wayland: #{!keymap.null?}"
		{% end %}

		# TODO: xkb uses these properly?
		# XKB_DEFAULT_LAYOUT=gb <- is used by default anyway by xkbc
		# XKB_DEFAULT_OPTIONS=compose:ralt,ctrl:nocaps
		
		if keymap.null?
			# Standard way on X11, returns e.g. "us(altgr-intl)". Can also return a value on Wayland systems,
			# but those should have been caught above already
            # TODO: use x11 library instead
			x11_keymap = `setxkbmap -print | grep xkb_symbols | awk '{print $4}' | awk -F"+" '{print $2}'`
			names =
				if ! x11_keymap.empty?
					keymap_split = x11_keymap.strip.split(/[()]/)
					{% if ! flag?(:release) %}
						puts "[debug] Evdev key lookup: X11 keymap: #{keymap_split}"
					{% end %}
					LibXKBCommon::RuleNames.new(layout: keymap_split[0], variant: keymap_split[1]?.try &.to_unsafe || Pointer(UInt8).null)
				else
					LibXKBCommon::RuleNames.new(layout: nil)
				end
            ctx = LibXKBCommon.context_new(LibXKBCommon::ContextFlags::NoFlags)
			keymap = LibXKBCommon.keymap_new_names(ctx, pointerof(names), LibXKBCommon::KeymapCompileFlags::NoFlags)
            LibXKBCommon.context_free(ctx)
		end
		if keymap.nil?
			raise "Could not determine keymap! Please open up a GitHub issue."
		end
		keymap
	end
end