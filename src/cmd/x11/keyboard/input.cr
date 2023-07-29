require "time"
# Input [, OutputVar, Options, EndKeys, MatchList]
class Cmd::X11::Keyboard::Input < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	def self.sets_error_level; true end
	def run(thread, args)
		terminated_prior = false
		if current_channel = thread.runner.current_input_channel
			current_channel.send("NewInput")
			terminated_prior = true
			thread.runner.current_input_channel = nil
		end

		out_var = args[0]?
		if ! out_var
			return terminated_prior ? "0" : "1"
		end

		ignore_backspace = false
		case_sensitive = false
		max = 16_383
		timeout = nil
		visible = false
		match_anywhere = false
		ignore_generated_input = false
		thread.parse_letter_options(args[1]? || "") do |c, n|
			case c
			when 'b' then ignore_backspace = true
			when 'c' then case_sensitive = true
			when 'i' then ignore_generated_input = true
			when 'l' then max = n.try &.to_i || 1
			when 't' then timeout = n
			when 'v' then visible = true
			when '*' then match_anywhere = true
			end
		end

		end_keys = thread.parse_key_combinations(args[2]? || "")

		match_phrases = (args[3]? || "").gsub(",,", "\0").split(",").map &.gsub("\0", ",")

		channel_error_level = Channel(::String).new
		thread.runner.current_input_channel = channel_error_level

		if ! visible
			thread.runner.display.hotkeys.block_input
		end

		buf = ""
		last_key_event = nil
		listener = thread.runner.display.register_key_listener do |key_event, keysym, char, is_paused| # TODO: inconsistency: KeyEvent/char vs. KeyCombination.key_name
			next if is_paused && ignore_generated_input
			next if key_event.type != ::X11::KeyPress
			last_key_event = key_event
			end_key = end_keys.find { |k| k.keysym == keysym }
			if end_key
				next channel_error_level.send("EndKey:#{end_key.key_name}")
			end
			if ! ignore_backspace && char == '\b' # ::X11::XK_BackSpace
				buf = buf.empty? ? "" : buf[...-1]
				next
			end
			next if ! char
			buf += char
			match = match_phrases.index do |phrase|
				match_buf = case_sensitive ? buf : buf.downcase
				phrase = case_sensitive ? phrase : phrase.downcase
				if match_anywhere
					match_buf.includes?(phrase)
				else
					match_buf == phrase
				end
			end
			if match
				next channel_error_level.send("Match")
			end
			if buf.size >= max
				next channel_error_level.send("Max")
			end
		end

		ret = select
		when r = channel_error_level.receive
			r
		# Neither Time::Span::MAX nor Time::Span::ZERO works here
		when timeout(timeout ? timeout.not_nil!.seconds : 302400000.seconds)
			"Timeout"
		end

		thread.runner.current_input_channel = nil

		thread.runner.display.unregister_key_listener(listener)

		# TODO: tests (like hotstring.cr)
		if last_key_event
			# Same xdotool workaround as in hotstring.cr / send.cr
			last_key_up = XDo::LibXDo::Charcodemap.new
			last_key_up.code = last_key_event.not_nil!.keycode
			thread.runner.display.x_do.keys_raw [last_key_up], pressed: false, delay: 0
		end

		if ! visible
			thread.runner.display.hotkeys.unblock_input
		end

		thread.runner.set_user_var(out_var, buf)

		ret
	end
end