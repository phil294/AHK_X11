class Cmd::Misc::Run < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	@wait = false
	# returns either `false` on failure or `i64` exit code or pid, depending on *@wait*.
	private def try_execute(line, chdir = nil, stdout = false, stderr = false)
		cmd = Process.parse_arguments(line)[0]?
		return false, "", "" if ! cmd || ! ::Process.find_executable(cmd)
		chdir = nil if chdir && chdir.empty?
		stdout_m = stdout ? IO::Memory.new : Process::Redirect::Close
		stderr_m = stderr ? IO::Memory.new : Process::Redirect::Close
		begin
			p = Process.new(line, chdir: chdir, shell: true, output: stdout_m, error: stderr_m)
		rescue e : IO::Error
			return false, "", ""
		end
		ret = @wait ? p.wait.exit_code.to_i64 : p.pid
		return ret, stdout_m.to_s, stderr_m.to_s
	end
	def run(thread, args)
		target = args[0]
		pwd = args[1]?
		opt = thread.parse_word_options(args[2]? || "")
		output_var_pid = args[3]?
		output_stdout = args[4]?
		output_stderr = args[5]?

		if target.starts_with?("open ")
			target = target[5..]
			open = true
		elsif target.starts_with?("edit ")
			target = target[5..]
			edit = true
		elsif target.starts_with?("explore ")
			target = target[8..]
			edit = true
		elsif target.starts_with?("print ")
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
			success, stdout, stderr = try_execute("gtk-launch \"$(xdg-mime query default text/plain)\" '#{target}'", chdir: pwd, stdout: !!output_stdout, stderr: !!output_stderr)
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
			success, stdout, stderr = try_execute(target, chdir: pwd, stdout: !!output_stdout, stderr: !!output_stderr)
		end

		if ! success
			path = ::File.expand_path(target)
			success = try_execute("xdg-open " + path) && ""
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