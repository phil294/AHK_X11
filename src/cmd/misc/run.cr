class Cmd::Misc::Run < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	@wait = false
	# returns either `false` on failure or `i64` exit code or pid, depending on *@wait*.
	private def try_execute(thread, line, chdir = nil, stdout = false, stderr = false)
		args = Process.parse_arguments(line).map do |arg|
			Util::AhkString.parse_string(arg, thread.runner.settings.escape_char) do |var_name_lookup|
				thread.get_var(var_name_lookup)
			end
		end
		return false, "", "" if ! args[0]? || ! ::Process.find_executable(args[0])
		{% if ! flag?(:release) %}
			puts "[debug] runcmd[#{thread.id}]: cmd=#{args[0]} args=#{args[1..]}"
		{% end %}
		chdir = nil if chdir && chdir.empty?
		stdout_m = stdout ? IO::Memory.new : Process::Redirect::Close
		stderr_m = stderr ? IO::Memory.new : Process::Redirect::Close
		begin
			p = Process.new(args[0], args[1..], chdir: chdir, output: stdout_m, error: stderr_m)
		rescue e : IO::Error
			return false, "", ""
		end
		ret = @wait ? p.wait.exit_code.to_i64 : p.pid
		return ret, stdout_m.to_s, stderr_m.to_s
	end
	def run(thread, args)
		target_raw = @args[0]
		target = args[0]
		pwd = args[1]?
		opt = thread.parse_word_options(args[2]? || "")
		output_var_pid = args[3]?
		output_stdout = args[4]?
		output_stderr = args[5]?

		if target_raw.starts_with?("open ")
			target_raw = target_raw[5..]
			target = target[5..]
			open = true
		elsif target_raw.starts_with?("edit ")
			target_raw = target_raw[5..]
			target = target[5..]
			edit = true
		elsif target_raw.starts_with?("explore ")
			target_raw = target_raw[8..]
			target = target[8..]
			edit = true
		elsif target_raw.starts_with?("print ")
			target_raw = "lp " + target_raw[6..]
			target = "lp " + target[6..]
			open = true
		else
			open = true
		end

		success = false
		stdout = stderr = ""

		# TODO: This only sets up the dialog but the printing logic is missing. Not sure
		# how to implement the draw_page callback for arbitrary file types, so I disabled
		# this and made `print` just send the file to `lp` instead for now.
		# if print
		# 	thread.runner.display.gui.act do
		# 		print_op = ::Gtk::PrintOperation.new
		# 		print_op.run ::Gtk::PrintOperationAction::PRINT_DIALOG, nil
		#		success = ...
		# 	end

		if edit
			success, stdout, stderr = try_execute(thread, "gtk-launch '#{`xdg-mime query default text/plain`.strip}' '#{target_raw}'", chdir: pwd, stdout: !!output_stdout, stderr: !!output_stderr)
		end

		thread.runner.display.gui.act do
			begin
				if target.starts_with?("www.")
					target = "http://#{target}"
				end
				# works for uris etc., but not for local files
				success = ::Gio.app_info_launch_default_for_uri(target, nil)
			rescue
			end
		end
		
		if ! success && open
			success, stdout, stderr = try_execute(thread, target_raw, chdir: pwd, stdout: !!output_stdout, stderr: !!output_stderr)
		end

		if ! success
			success = try_execute(thread, "xdg-open " + target_raw) && ""
		end

		if success
			thread.runner.set_user_var(output_stdout, stdout) if output_stdout && ! output_stdout.empty?
			thread.runner.set_user_var(output_stderr, stderr) if output_stderr && ! output_stderr.empty?
		end

		if opt["useerrorlevel"]?
			thread.set_thread_built_in_static_var("ErrorLevel", success ? "0" : "ERROR")
		else
			if ! success
				raise ::Run::RuntimeException.new "Failed attempt to launch program or document: #{target}"
			elsif @wait
				thread.set_thread_built_in_static_var("ErrorLevel", success.to_s)
			end
		end

		if output_var_pid && ! output_var_pid.empty? && ! @wait && success.is_a?(Int64)
			thread.runner.set_user_var(output_var_pid, success.to_s)
		end
	end
end