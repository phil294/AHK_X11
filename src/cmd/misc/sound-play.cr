# SoundPlay, Filename [, wait]
class Cmd::Misc::SoundPlay < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 2 end
	def self.sets_error_level; true end
	def run(thread, args)
		if previous_pid = thread.runner.settings.sound_play_pid
			Process.signal(Signal::KILL, previous_pid) # Kill because cvlc is rebellious
		end
		# Ordered by what would be most preferable
		players = [
			# ffmpeg seems to work perfectly all the time:
			{ cmd: "ffplay", params: ["-autoexit", "-nodisp", "-nostats", "-hide_banner"] },
			# vlc: For videos, this flashes the focus of the current window, but other than that, it works well.
			# Allegedly `-Idummy` is the new version of `-Vdummy` but on Arch, only the latter worked to prevent
			# the actual full Gui from starting.
			{ cmd: "cvlc", params: ["-Idummy", "-Vdummy"] of ::String },
			{ cmd: "paplay", params: [] of ::String }, # Cannot play videos
			{ cmd: "mpg123", params: [] of ::String }, # Cannot play .wav files
			{ cmd: "aplay", params: [] of ::String }, # Cannot play mp3 files
		]
		player = players.find { |p| Process.find_executable(p[:cmd]) }
		return "1" if ! player
		p = Process.new(player[:cmd], player[:params] + [args[0]])
		thread.runner.settings.sound_play_pid = p.pid
		if args[1]? && ["wait","1"].includes?(args[1].downcase)
			result = p.wait.exit_code
			return result == 0 ? "0" : "1"
		end
		"0"
	end
end