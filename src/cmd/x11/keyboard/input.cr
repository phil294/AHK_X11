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
		end_keysyms = end_keys.map do |combo|
			thread.runner.display.adapter.key_combination_to_keysym(combo)
		end

		match_phrases = (args[3]? || "").gsub(",,", "\0").split(",").map &.gsub("\0", ",")

		channel = Channel(::String).new
		thread.runner.current_input_channel = channel

		if ! visible
			thread.runner.display.hotkeys.block_input
		end

		buf = ""
		listener = thread.runner.display.register_key_listener do |key_event, keysym, is_paused|
			next if is_paused && ignore_generated_input
			next if ! key_event.down
			end_key_i = end_keysyms.index &.== keysym
			if end_key_i # TODO: test
				next channel.send("EndKey:#{end_keys[end_key_i].key_name}")
			end
			if ! ignore_backspace && keysym == ::X11::XK_BackSpace
				buf = buf.empty? ? "" : buf[...-1]
				next
			end
			char = key_event.text
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
				next channel.send("Match")
			end
			if buf.size >= max
				next channel.send("Max")
			end
		end

		ret = select
		when r = channel.receive
			r
		# Neither Time::Span::MAX nor Time::Span::ZERO works here
		when timeout(timeout ? timeout.not_nil!.seconds : 302400000.seconds)
			"Timeout"
		end

		thread.runner.current_input_channel = nil

		thread.runner.display.unregister_key_listener(listener)

		if ! visible
			thread.runner.display.hotkeys.unblock_input
		end

		thread.runner.set_user_var(out_var, buf)

		ret
	end
end