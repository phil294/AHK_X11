require "atspi"

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

		# Finds the first window-like accessible that matches one of the windows (or window-like on Wayland).
		# No results caching here.
		def find_top_level_accessible(thread, windows, match_text = nil, exclude_text = nil, include_hidden = false)
			init
			apps = all_apps
			# There is no match by window XID (https://gitlab.gnome.org/GNOME/at-spi2-core/-/issues/21),
			# so bland comparison by pid or title or size is necessary, even on X11:
			pids = windows
				.map { |w| w.pid }
				.reject &.nil?
			if ! pids.empty?
				app = apps.find do |a|
					pids.includes?(a.process_id)
				end
				return nil if ! app
				apps = [ app ]
			end
			return nil if apps.empty?
			tl_children = apps.flat_map { |app|
				children(app, include_hidden: include_hidden).select { |tl_child|
					top_level_window?(tl_child) } }
			return nil if tl_children.empty?
			return tl_children.first if tl_children.size == 1
			names = windows
				.map { |w| w.name }
				.reject &.nil?
			if ! names.empty?
				tl_children.select! { |t| names.includes?(t.name) }
			end
			# False positives *are* possible here, e.g. if the popup has the same window title
			# as another window of the same PID while the popup has no atspi title (e.g.
			# the default in ahk guis, see below)
			return tl_children.first if tl_children.size == 1
			if match_text && ! match_text.empty? || exclude_text && ! exclude_text.empty?
				tl_children.select! do |tl_child|
					win_texts = get_all_texts_of_top_level_accessible(thread, tl_child, include_hidden: false)
					next false if ! win_texts
					if match_text && ! match_text.empty?
						next false if ! win_texts.index &.includes?(match_text)
					end
					if exclude_text && ! exclude_text.empty?
						next false if win_texts.index &.includes?(exclude_text)
					end
					true
				end
				return tl_children.first if tl_children.size == 1
			end
			win_with_size = windows.find &.size
			if win_with_size
				# Some windows have no or missing title in atspi. Example: Gtk alerts, such as our
				# MsgBox. So the window title match didn't help here. Also, there can be multiple
				# windows or caller passed multiple.
				# So we fall back to approximating sizes. Cannot strictly compare sizes
				# because these may differ depending on decorations...
				win_w, win_h = win_with_size.size.not_nil!
				window_size = (win_w + win_h).to_i
				tl_children.sort! { |t1, t2|
					t1_e = t1.extents(::Atspi::CoordType::Screen)
					t2_e = t2.extents(::Atspi::CoordType::Screen)
					(window_size - t1_e.width - t1_e.height).abs - (window_size - t2_e.width - t2_e.height).abs
				}
			end
			return tl_children.first?
		end
		# Finds the first match for *text_or_class_NN* inside *top_level_accessible* or `nil` if
		# no match was found.
		def find_descendant_of_top_level_accessible(thread, top_level_accessible, text_or_class_NN, include_hidden = false)
			return nil if text_or_class_NN.empty?
			descendant : ::Atspi::Accessible? = nil
			# TODO: when an error throws here (e.g. missing hash key), this should result in an unexpected error and abort
			# but instead it's caught by display (as expected) and re-thrown as runtime error instead, AND
			# TODO: its stack trace is missing the info of the error line
			cache_accessible_by_class_nn = thread.cache.accessible_by_class_nn_by_top_level_accessible[top_level_accessible.hash]

			class_NN_role, class_NN_path = from_class_NN(text_or_class_NN)
			if class_NN_role
				# This is 99% a class_NN. These are essentially control paths so we can try to
				# get the control without searching.
				class_NN = text_or_class_NN
				descendant = cache_accessible_by_class_nn[class_NN]?
				return descendant if descendant

				k = top_level_accessible
				path_valid = class_NN_path.each do |i|
					break false if i > k.child_count - 1
					k = k.child_at_index(i)
				end
				if path_valid != false && k.role_name == class_NN_role
					descendant = k
				end
				if descendant
					cache_accessible_by_class_nn[class_NN] = descendant.not_nil!
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
			# # matches = top_level_accessible.matches(rule, Atspi::CollectionSortOrder::CANONICAL, 5, true)
			each_descendant_of_top_level_accessible(thread, top_level_accessible, include_hidden: include_hidden) do |acc, _, acc_class_NN|
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
		def find_descendant_of_top_level_accessible(thread, top_level_accessible, *, x, y, include_hidden = false)
			# Fast; most of the time, it returns the accurate deepest child, but sometimes
			# it just returns the first child even though that one has many descendants itself
			# e.g. xfce4-appfinder
			top_match = top_level_accessible.accessible_at_point(x, y, ::Atspi::CoordType::Screen)
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
			# `top_level_accessible` directly, but this way, it is usually very fast.
			# This is in contrast to find-by-text (see comment inside find_descendant above)
			# where manual seems to be the only way.
			iter_descendants(match, nil, false) do |acc, path, class_NN, nest_level|
				if nest_level <= match_nest_level
					next nil # stop
				end
				contained = acc.contains(x, y, ::Atspi::CoordType::Screen)
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
			
			thread.cache.accessible_by_class_nn_by_top_level_accessible[top_level_accessible.hash][match_class_NN] = match
			{% if ! flag?(:release) %}
				puts "[debug] find_descendant name:#{match.name}, role:#{match.role}, classNN:#{match_class_NN}, text:#{match ? get_text(match) : ""}, actions:#{get_actions(match)[1]}, selectable:#{selectable?(match)}. top_match_path:#{top_match_path}, match_path:#{match_path}, top_match role:#{top_match.role}, top_match name:#{top_match.name}"
			{% end %}
			return match, match_class_NN
		end
		def all_apps
			init
			desktop = ::Atspi.desktop(0)
			# it's common for the top level window to not have the visible property
			# even when it *is*, so as an exception, we also include hidden.
			# child_count>0 at least filters out the nonsense: This is the same
			# approach taken by Accerciser.
			children(desktop, include_hidden: true).select &.child_count.>(0)
		end
		def children(accessible, *, max = nil, include_hidden = false)
			accessible.child_count.times do |i|
				break if max && i > max
				child = accessible.child_at_index(i)
				# happens randomly from time to time... without check, `hidden?` will segfault
				next if child.nil? || child.to_unsafe.nil? || child.to_unsafe.null?
				if ! include_hidden
					next if hidden?(child)
				end
				yield child, i
			end
		end
		def children(accessible, *, max = nil, include_hidden = false)
			accs = [] of ::Atspi::Accessible
			children(accessible, max: max, include_hidden: include_hidden) do |a|
				accs << a
			end
			accs
		end
		# The block is run for every descendant and must return either:
		# `true`: Continue and traverse the children of this accessible;
		# `false`: Continue but skip the children of this accessible, so continue on
		#     to the next sibling or parent;
		# `nil`: Stop.
		def each_descendant_of_top_level_accessible(thread, top_level_accessible, *, include_hidden = false, max_children = nil, skip_non_interactive = false, &block : ::Atspi::Accessible, Array(Int32), String, Int32 -> Bool?)
			return if ! top_level_accessible
			cache_accessible_by_class_nn = thread.cache.accessible_by_class_nn_by_top_level_accessible[top_level_accessible.hash]
			iter_descendants(top_level_accessible, max_children, include_hidden) do |desc, path, class_NN, nest_level|
				cache_accessible_by_class_nn[class_NN] = desc
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
				children(accessible, max: max_children, include_hidden: include_hidden) do |child, i|
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
			role == ::Atspi::Role::Frame || role == ::Atspi::Role::Window || role == ::Atspi::Role::Dialog || role == ::Atspi::Role::FileChooser || role == ::Atspi::Role::Alert
		end
		# checks if the element is both visible and showing. Does not mean that the tl window
		# itself isn't hidden behind another window though.
		# Can also be faulty for some apps like xfce4-appfinder which
		# just scramble coordinates of hidden children instead.
		# To prevent having to query extents for all elements, the latter is not checked.
		# If required, this needs to be done with AHK code.
		private def hidden?(accessible)
			state_set = accessible.state_set
			! state_set.contains(::Atspi::StateType::Showing) || ! state_set.contains(::Atspi::StateType::Visible)
		end
		private def selectable?(accessible)
			accessible.state_set.contains(::Atspi::StateType::Selectable)
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
			text = accessible.text_iface.text(0, -1).gsub('￼', "").strip()
			text = accessible.name.gsub('￼', "").strip() if text.empty?
			text.empty? ? nil : text
		end
		def set_text(accessible, text)
			iface = begin
				accessible.editable_text_iface
			rescue e
				return false
			end
			iface.text_contents = text
			true
		end
		# returns an array of recursive text strings, no duplication present.
		# only 1,000 descendant nodes are queried each to not kill performance completely
		# with windows with very large lists (e.g. Gtk tables: each cell is a child of the table)
		def get_all_texts_of_top_level_accessible(thread, accessible, *, include_hidden)
			strings = [] of ::String
			each_descendant_of_top_level_accessible(thread, accessible, include_hidden: include_hidden, max_children: 1000) do |descendant, _, class_NN|
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
		def get_pos(accessible)
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
			ext = accessible.extents(::Atspi::CoordType::Screen)
			x = ext.x
			y = ext.y
			w = ext.width
			h = ext.height
			# Takes about 0.1 ms, so there's no point in caching this just yet (see also Thread.cache)
			# FIXME. broken now. also how does this whole function behave/should behave on wayland anyway?
			return x, y, w, h
			# loc = win.location
			# begin
			# 	return x - loc[0], y - loc[1], w, h
			# rescue
			# 	return -1, -1, w, h
			# end
		end
	end
end