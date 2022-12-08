# require "gobject/atspi"

module Run
	# Atspi is the framework-independent tooling for accessibility in the Linux world.
	# It is supported (often hidden behind config flags) by all big frameworks except Tk.
	#
	# Atspi requests can be very slow, but typically only for the first command and
	# only for some applications (for example, any first request to Firefox accessible
	# takes *seconds*. But it seems that once a command has run, some caching is active and
	# incremental changes to open windows are adopted automatically.
	# Not sure about performance implications, but in any way, Atspi appears rather resource heavy
	# and slow, so it makes sense to lazily initialize it.
	class AtSpi
		@is_init = false
		def init
			return if @is_init
			atspi_status = ::Atspi.init
			# TODO: test this out, does it show the actual command that failed to the user?
			raise Run::RuntimeException.new "Cannot access ATSPI (window control info bus). Maybe you need to install libatspi2.0. Init error code: #{atspi_status.to_s}" if atspi_status != 0
			@is_init = true
		end

		# Finds the first x11 window-like accessible corresponding to the window's pid and name
		# or `nil` if no match was found.
		# There is no match by window XID. (https://gitlab.gnome.org/GNOME/at-spi2-core/-/issues/21)
		private def find_window(thread, win, include_hidden = false)
			init
			wid = win.window
			thread.cache.accessible_by_class_nn_by_window_id[wid] ||= {} of String => ::Atspi::Accessible
			frame = thread.cache.top_level_accessible_by_window_id[wid]?
			return frame if frame
			pid = win.pid
			window_name = win.name
			app = each_app do |app|
				break app if app.process_id == pid
			end
			if app
				frame = each_child(app, include_hidden: include_hidden) do |tl_child|
					break tl_child if top_level_window?(tl_child) && tl_child.name == window_name
				end
				if ! frame
					frame = each_child(app, include_hidden: include_hidden) do |tl_child|
						# Some popup windows have no title in atspi. Not sure who's responsibility
						# it is to set those, so if it is a recurring bug or application-specific.
						# TODO: In either case, we should compare win size next as that is a better
						# match criteria than empty win title as below. Also do that when there are
						# multiple name matches above. Win size matching is not easy though because
						# libxdo returns geometry including borders and decoration but atspi does not...
						break tl_child if top_level_window?(tl_child) && tl_child.name.empty?
					end
				end
			end
			if frame
				thread.cache.top_level_accessible_by_window_id[wid] = frame
				return frame
			end
			raise Run::RuntimeException.new "Could not determine Control Info for window '#{window_name}'!

Some things may not work as expected. You can press OK and the script will continue, or read on below on how to fix this:

The window '#{window_name} #{app ? " is recognized but has no control children, according the AT-SPI information it exposes" : " is not recognized by AT-SPI"}. Usually, this means one of the following:
- You haven't enabled the assistive technologies setting for your distribution. There's usually a single checkbox somewhere to be found to enable it. After enabling, you need to reboot.
- If the window is a Chromium-based browser such as Chrome or Brave or an Electron-based application such as VSCode, Slack, Spotify, Discord and many more (www.electronjs.org/apps), it needs to be launched with two tweaks:
    1. Set environment variable ACCESSIBILITY_ENABLED to value 1. You can e.g. enable this globally by adding another line with content ACCESSIBILITY_ENABLED=1 into the file /etc/environment and then restarting your computer.
    2. Add argument --force-renderer-accessibility. You can do so by editing the program's \"Desktop file\", or starting it from command line and passing it there.
  Example for Chrome:
    export ACCESSIBILITY_ENABLED=1
    chrome --force-renderer-accessibility
- If the window is a Java application, you need to install the ATK bridge: For Debian-based applications, this is libatk-wrapper-java. For Arch Linux based ones, it's java-atk-wrapper-openjdk8 (depending on the Java version)
- In the rare case that the window is an exotic, old application built with Qt4, such as some programs that haven't been maintained since 2015, you need to install qt-at-spi.
- According to the internet, these following environment variables may also help: GNOME_ACCESSIBILITY=1, QT_ACCESSIBILITY=1, GTK_MODULES=gail:atk-bridge and QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1. This is probably only relevant for outdated programs too, if ever.
- If you tried all of that and it still doesn't work, this program may not support control access at all. Please consider opening up an issue at github.com/phil294/ahk_x11 so we can investigate. Almost every program out there will work some way or another!
- Programs built with Tk (rare) usually never work."
		end
		# Finds the first match for *text_or_class_NN* inside *win* or `nil` if
		# no match was found.
		def find_descendant(thread, win, text_or_class_NN, include_hidden = false)
			descendant : ::Atspi::Accessible? = nil

			accessible = find_window(thread, win, include_hidden)
			return nil if ! accessible

			class_NN_role, class_NN_path = from_class_NN(text_or_class_NN)
			if class_NN_role
				class_NN = text_or_class_NN
				# This is 99% a class_NN. These are essentially control paths so we can try to
				# get the control without searching.
				descendant = thread.cache.accessible_by_class_nn_by_window_id[win.window][class_NN]?
				return descendant if descendant
				k = accessible
				path_valid = class_NN_path.each do |i|
					break false if i > k.child_count - 1
					k = k.child_at_index(i)
				end
				if path_valid != false && k.role_name == class_NN_role
					descendant = k
				end
				if descendant
					thread.cache.accessible_by_class_nn_by_window_id[win.window][class_NN] = descendant.not_nil!
					return descendant
				else
					# Also stop here: Don't support actual class_NN-like text matches (very unlikely)
					# at the expense of running slow text match logic every time a class_NN could
					# not be found (moderately likely).
					return descendant
				end
			end

			text = text_or_class_NN
			class_NN = ""
			# Textual match
			# Below is commented out an alternative way of matching with `.matches()`: This compiles when you
			# fix gtk type error attributes to `Void**` but fails at runtime with error
			# `No such object path '/org/a11y/atspi/accessible/2147483692'`. This is probably because the sample
			# element did not implement Collection interface. But not many ever do, really...
			# So this is useless, unless I made a mistake.
			# This probably wouldn't traverse children anyway because while we pass `traverse: true` to `matches()`,
			# docs name this param as "unsupported". It would however still help very much for filtering
			# children when there are many of them, like in gtk tree where there are often many thousands,
			# slowing down everything *so much*.
			# I couldn't find a "find descendant by text" function in the api, and pyatspi also builds its own
			# `findDescendants()` for this with custom filter rules which then also manually traverses all
			# descendants, like we do here.
			# Weird because there *are* methods which allow quick access, namely `accessible_at_point`, but
			# that won't help us with text matching... :-(
			# There is also no helpful general overview documentation of atspi as far as I am aware, and
			# matrix gtk folks didn't want to help out either, so we're stuck with slow traversing for now.
			# TODO: check libatspi source to verify
			# At least class_nn access (above) should be quick.
			# # match_none = ::Atspi::CollectionMatchType::NONE
			# # null = Pointer(Void).null
			# # rule = ::Atspi::MatchRule.new(::Atspi::StateSet.new([] of UInt32), match_none, pointerof(null), match_none, [] of String, match_none, [] of String, match_none, false)
			# # matches = accessible.matches(rule, Atspi::CollectionSortOrder::CANONICAL, 5, true)
			each_descendant(thread, win, include_hidden: include_hidden) do |acc, _, acc_class_NN|
				is_match = get_text(acc) == text
				if is_match
					descendant = acc
					{% if ! flag?(:release) %}
						puts "[debug] find_descendant #{acc.name}, #{acc.role}, #{acc_class_NN}"
					{% end %}
				end
				is_match ? nil : true
			end
			descendant
		end
		# Finds the most specific accessible that contains the screen-wide coordinate. and combine both
		# Cannot use relative coords because they are usually baloney in atspi.
		def find_descendant(thread, win, *, x, y, include_hidden = false)
			accessible = find_window(thread, win, include_hidden)
			return nil, nil if ! accessible
			# Fast; most of the time, it returns the accurate deepest child, but sometimes
			# it just returns the first child even though that one has many descendants itself
			# e.g. xfce4-appfinder
			top_match = accessible.accessible_at_point(x, y, ::Atspi::CoordType::SCREEN)
			return nil, nil if ! top_match
			# If we went the completely manual way, class_NN would already be known to us,
			# but the shortcut made this impossible, so we now need to reverse look it up (up to now)
			# because this is custom logic and not provided by atspi.
			# Always omit the top level window itself.
			top_match_path = to_path(top_match)[1..]

			match = top_match
			match_path = [] of Int32
			match_nest_level = -1
			# ...that's why we need to check for more children and go the manual way too.
			# If the previous shortcut weren't available, we'd have to apply this to
			# `accessible` directly, but this way, it is usually very fast.
			# This is in contrast to find-by-text (see comment inside find_descendant above)
			# where manual seems to be the only way.
			iter_descendants(match, nil, false) do |acc, path, class_NN, nest_level|
				if nest_level <= match_nest_level
					next nil # stop
				end
				contained = acc.contains(x, y, ::Atspi::CoordType::SCREEN)
				if contained
					match = acc
					match_path = path
					match_nest_level = nest_level
				end
				# traverse children?
				# `next contained`: This would be the proper solution if all `contains` were
				# accurate, but accs don't have to recursively contain all children, sometimes
				# children can lie outside or be bigger or have negative pos etc., e.g. tab layout,
				# so even this manual coord check isn't perfect.
				# That's why we always need to go through all children. While this *could*
				# be slow, it normally isn't due to pre-filtering with accessible_at_point.
				next true
			end

			if match == top_match
				match_path = top_match_path
			else
				# `to_path(match)` can be unreliable / return an invalid path (LibreOffice, Thunar)
				match_path = top_match_path + match_path
			end
			match_class_NN = to_class_NN(match_path, match.role_name)
			
			thread.cache.accessible_by_class_nn_by_window_id[win.window][match_class_NN] = match
			{% if ! flag?(:release) %}
				puts "[debug] find_descendant name:#{match.name}, role:#{match.role}, classNN:#{match_class_NN}, text:#{match ? get_text(match) : ""}, actions:#{get_actions(match)[1]}, selectable:#{selectable?(match)}. top_match_path:#{top_match_path}, match_path:#{match_path}, top_match role:#{top_match.role}, top_match name:#{top_match.name}"
			{% end %}
			return match, match_class_NN
		end
		def each_app
			init
			desktop = ::Atspi.desktop(0)
			# it's common for the top level window to not have the visible property
			# even when it *is*, so as an exception, we also include hidden.
			# child_count>0 at least filters out the nonsense: This is the same
			# approach taken by Accerciser.
			each_child(desktop, include_hidden: true) do |app|
				next if app.child_count == 0
				yield app
			end
		end
		def each_child(accessible, *, max = nil, include_hidden = false)
			accessible.child_count.times do |i|
				break if max && i > max
				child = accessible.child_at_index(i)
				if ! include_hidden
					next if hidden?(child)
				end
				yield child, i
			end
		end
		# The block is run for every descendant and must return either:
		# `true`: Continue and traverse the children of this accessible;
		# `false`: Continue but skip the children of this accessible, so continue on
		#     to the next sibling or parent;
		# `nil`: Stop.
		def each_descendant(thread, win, *, include_hidden = false, max_children = nil, skip_non_interactive = false, &block : ::Atspi::Accessible, Array(Int32), String, Int32 -> Bool?)
			accessible = find_window(thread, win, include_hidden)
			return if ! accessible
			iter_descendants(accessible, max_children, include_hidden) do |desc, path, class_NN, nest_level|
				thread.cache.accessible_by_class_nn_by_window_id[win.window][class_NN] = desc
				if skip_non_interactive
					next true if ! interactive?(desc)
				end
				block.call desc, path, class_NN, nest_level
			end
		end
		private def iter_descendants(accessible, max_children, include_hidden, nest_level = 0, path = [] of Int32, &block : ::Atspi::Accessible, Array(Int32), String, Int32 -> Bool?)
			# Elements would actually expose a `.accessibility_id` property, but it's
			# usually empty :-( So we forge an artificial, unique path for each element and
			# just pretend it's an actual ahk-like ClassNN: e.g. `push_button_0_1_0`
			class_NN = to_class_NN(path, accessible.role_name)
			response = yield accessible, path, class_NN, nest_level
			return nil if response == nil
			if response
				each_child(accessible, max: max_children, include_hidden: include_hidden) do |child, i|
					response = iter_descendants(child, max_children, include_hidden, nest_level + 1, path + [i], &block)
					break if response == nil
				end
			end
			response
		end
		# check if the accessible is what X11 understands as a window
		private def top_level_window?(accessible)
			role = accessible.role
			# https://docs.gtk.org/atspi2/enum.Role.html
			# may not be complete yet
			role == ::Atspi::Role::FRAME || role == ::Atspi::Role::WINDOW || role == ::Atspi::Role::DIALOG || role == ::Atspi::Role::FILE_CHOOSER || role == ::Atspi::Role::ALERT
		end
		# checks if the element is both visible and showing. Does not mean that the tl window
		# itself isn't hidden behind another window though.
		# Can also be faulty for some apps like xfce4-appfinder which
		# just scramble coordinates of hidden children instead.
		# To prevent having to query extents for all elements, the latter is not checked.
		# If required, this needs to be done with AHK code.
		private def hidden?(accessible)
			state_set = accessible.state_set
			! state_set.contains(::Atspi::StateType::SHOWING) || ! state_set.contains(::Atspi::StateType::VISIBLE)
		end
		private def selectable?(accessible)
			accessible.state_set.contains(::Atspi::StateType::SELECTABLE)
		end
		private def interactive?(accessible)
			begin
				n_actions = accessible.n_actions
			rescue
				n_actions = 0
			end
			n_actions > 0 || selectable?(accessible)
		end
		# Selecting always happens somewhere in the parent chain
		private def select!(accessible)
			child_i = accessible.index_in_parent
			parent = accessible.parent
			while parent
				begin
					# parent.interfaces.contains("Selection") isn't type safe implemented so we need this:
					sel = parent.selection_iface
					break parent
				rescue
				end
				child_i = parent.index_in_parent
				parent = parent.parent
			end
			parent.select_child(child_i) if parent
		end
		def get_text(accessible)
			text = begin
				# TODO: textareas etc?
				# TODO: only if has no children?
				accessible.text_iface.text(0, -1)
			rescue e
				accessible.name
			end
			text = text.gsub('￼', "").strip()
			text.empty? ? nil : text
		end
		# returns an array of recursive text strings, no duplication present.
		# only 1,000 descendant nodes are queried each to not kill performance completely
		# with windows with very large lists (e.g. Gtk tables: each cell is a child of the table)
		def get_all_texts(thread, win, *, include_hidden)
			strings = [] of ::String
			each_descendant(thread, win, include_hidden: include_hidden, max_children: 1000) do |descendant, _, class_NN|
				text = get_text(descendant)
				strings << text if text
				true
			end
			strings
		end
		# Less of an action click, more of a general "interact" in the best possible compatible way.
		# Find the best selection or action, going upwards the parent chain if necessary.
		# This logic is necessary because apparently an action name can be *anything* but we
		# need best possible cross-application compatibility.
		# Returns the action index or -1 if selection or `nil` if nothing was found anywhere.
		def click(accessible)
			action_success = click_action(accessible)
			return action_success if action_success
			if selectable?(accessible)
				# e.g. tab panel selection
				{% if ! flag?(:release) %}
					puts "[debug] click select"
				{% end %}
				select!(accessible)
				return -1
			end
			return nil
		end
		private def click_action(accessible)
			# sorted by what would be most preferable
			names = StaticArray["click", "press", "push", "activate", "trigger", "mousedown", "mouse_down", "jump", "dodefault", "default", "start", "run", "submit", "select", "toggle", "send", "enable", "disable", "open", "into", "do", "make", "go", "expand", "on", "down", "enter", "focus", "have", "hold", "mouse", "pointer", "button"]
			actions = [] of String
			action_indexes = loop do
				accessible, actions = get_actions(accessible)
				return nil if ! accessible

				i_activate = actions.index("activate")
				i_edit = actions.index("edit")
				i_exp = actions.index("expand or contract")
				if i_activate && i_edit && i_exp
					# special stupid XFCE case in several apps such as Thunar, where `activate` is
					# not enough as it always runs the selected row even when our acc is another one.
					break [i_edit, i_activate]
				end

				match_i = names.each do |name|
					i = actions.index &.includes? name
					break i if i
				end
				match_i = 0 if ! match_i
				# `clickAncestor` sometimes fails (doesn't do anything) most notably in
				# VSCode, Electron apps in general perhaps? So let's go to that ancestor
				# ourselves, if encountered
				if actions[match_i].includes?("ancestor")
					accessible = accessible.parent
				else
					break [match_i]
				end
			end
			return nil if ! accessible

			{% if ! flag?(:release) %}
				puts "[debug] click choose action: #{action_indexes}/#{actions[action_indexes[0]]}"
			{% end %}
			action_indexes.each do |action_i|
				accessible.do_action(action_i)
			end
			action_indexes[0]
		end
		# Retrieves the list of actions names. If *accessible* has no actions,
		# it continues going upwards the parent chain until something was found.
		# Returns both the actions and that respective accessible where they are at.
		private def get_actions(accessible)
			actions = [] of String
			while actions.empty? && accessible
				begin
					n_actions = accessible.n_actions
				rescue
					n_actions = 0
				end
				n_actions.times do |i|
					actions << accessible.action_name(i).downcase
				end
				accessible = accessible.parent if actions.empty?
			end
			return actions.empty? ? nil : accessible, actions
		end
		# Goes up the ancestor chain and constructs a downwards array of `.index_in_parent` values,
		# Linear complexity, so hopefully never slow.
		private def to_path(accessible)
			path = [] of Int32
			k = accessible
			while k
				i = k.index_in_parent
				break if i < 0
				path << i
				k = k.parent
			end
			path.reverse
		end
		# e.g. for *path*=`[0,2]` and *role*=`a b` returns `a_b_0_2`
		private def to_class_NN(path, role)
			role.gsub(' ', '_') + '_' + path.map { |i| i.to_s }.join('_')
		end
		# e.g. for *txt*=`a_b_0_2` returns `a b`, `[0,2]`
		private def from_class_NN(txt)
			match = txt.match /([A-Za-z_]+)((_[0-9]+)+)/
			return nil, [] of Int32 if ! match
			role = match[1].gsub('_', ' ')
			path = match[2].split('_')[1..].map &.to_i
			return role, path
		end

		# Get x,y,w,h of an accessible. Like `accessible.extents(::Atspi::CoordType::WINDOW)`,
		# but more reliable.
		def get_pos(thread, win, accessible)
			# Most applications properly implement window-relative extents. There are two problems
			# with those:
			# 1. Those coordinates can be faulty (i.e., not match the actual coordinate in the window)
			#    in some applications, most prominently Firefox/Thunderbird. Here, even the top level frame
			#    has a small offset (when it should really be 0) which is probably equal to the window
			#    decoration bar/borders. This offset problem cascades down to all its children. Thus,
			#    it is necessary to remember (cache - this is stable) this offset to be able to subtract it
			#    inside ControlGetPos. This was done in the previous commit, check history
			# 2. Some apps don't support them at all, such as Audacious, where they are outright useless.
			#
			# So we need to ask for global coordinates instead which seems to always be correct (?),
			# and then convert them into relative ones.
			ext = accessible.extents(::Atspi::CoordType::SCREEN)
			x = ext.x
			y = ext.y
			w = ext.width
			h = ext.height
			# Takes about 0.1 ms, so there's no point in caching this just yet (see also Thread.cache)
			loc = win.location
			begin
				return x - loc[0], y - loc[1], w, h
			rescue
				return -1, -1, w, h
			end
		end
	end
end