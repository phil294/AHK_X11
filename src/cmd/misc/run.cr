# Run, Target [, WorkingDir, Max|Min|Hide|UseErrorLevel, OutputVarPID, OutputVarStdout, OutputVarStderr]
class Cmd::Misc::Run < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 6 end
	@wait = false
	private def args_to_str(args)
		args.map { |a| arg_to_str(a) }
		.join(' ')
	end
	private def arg_to_str(arg)
		"'" + arg.gsub("'", "'\\''") + "'"
	end
	# returns either `false` on failure or `i64` exit code or pid, depending on *@wait*.
	private def try_execute(thread, line, chdir = nil, stdout = false, stderr = false)
		args = Process.parse_arguments(line).map do |arg|
			Util::AhkString.parse_string(arg, thread.runner.settings.escape_char) do |var_name_lookup|
				thread.get_var(var_name_lookup)
			end
		end
		return false, "", "" if ! args[0]? || ! ::Process.find_executable(args[0])
		chdir = nil if chdir && chdir.empty?
		stdout_m = stdout ? IO::Memory.new : Process::Redirect::Close
		stderr_m = stderr ? IO::Memory.new : Process::Redirect::Close
		args_str = args_to_str(args) # (see below)
		run_as_user = thread.runner.settings.run_as_user
		run_as_password = thread.runner.settings.run_as_password
		if run_as_user && run_as_password
			# `sudo` asks for the *current* user's password which we don't want, so we have to
			# use `su` instead.
			# https://stackoverflow.com/a/3959957/3779853
			# Normally you'd use `Process.run(shell: false, stdin: IO::Memory.new(run_as_password)` but that
			# somehow doesn't work: `Password: su: Authentication token manipulation error` so sadly we have
			# to build our own shell cmd string to make use of Bash IO piping instead.
			user_str = arg_to_str(run_as_user)
			# We want to set `--login` so that vars like `$USER` etc are normalized for the user which is
			# required for some programs. But that also means we have to set some X vars for it to work:
			env_str = "DISPLAY=#{arg_to_str(ENV["DISPLAY"]?||"")} XAUTHORITY=#{arg_to_str(ENV["XAUTHORITY"]?||"")}"
			args_str = "#{env_str} #{args_str}"
			cmd = "su --login #{user_str} -c #{arg_to_str(args_str)} <<< #{arg_to_str(run_as_password)}"
			# Cannot use pkexec because it doesn't allow running as other user without admin rights or
			# gksu which isn't installed everywhere.
			`xhost si:localuser:#{user_str}`
			# Optimally, if the password is wrong, a proper error message should be shown, but this is a bit hard to implement here. Win ahk 1.0.24:
			# "Error: Launch Error (possibly related to RunAs). The current thread will exit.\n\nSpecifically: Logon failure: unknown user name or bad password.\n\n\nLine#\n       003: RunAs,root,sdfasdf\n--->    004: RunWait,Notepad.exe\n     005:Exit"
		else
			cmd = args_str
		end
		if ! @wait
			# Neither `bash -c 'stuff & disown'` nor `nohup` nor `p.close` nor io close args
			# work to prevent the spawned process from quitting once our main process exits,
			# only setsid does.
			cmd = "setsid #{cmd}"
		end
		{% if ! flag?(:release) %}
			puts "[debug] runcmd[#{thread.id}]: cmd=#{args[0]} args=#{args[1..]}, outcmd=#{cmd}"
		{% end %}

		env = {
			# AppImage/linuxdeploy-plugin-gtk sets several env vars *for the main binary itself*
			# but we need to prevent those overrides from being inherited by spawned sub processes
			# because it changes appearance and can even prevent proper functionality in some cases
			"GTK_DATA_PREFIX" => nil, "GDK_BACKEND" => nil, "XDG_DATA_DIRS" => nil, "GSETTINGS_SCHEMA_DIR" => nil, "GI_TYPELIB_PATH" => nil, "GTK_EXE_PREFIX" => nil, "GTK_PATH" => nil, "GTK_IM_MODULE_FILE" => nil, "GDK_PIXBUF_MODULE_FILE" => nil,
			# Was force set to EN in ahk_str.cr, revert
			"LC_ALL" => ENV["ahk_x11_LC_ALL_backup"],
			"ahk_x11_LC_ALL_backup" => nil
		}
		begin
			p = Process.new(cmd, shell: true, chdir: chdir, output: stdout_m, error: stderr_m, env: env)
		rescue e : IO::Error
			return false, "", ""
		end
		ret = @wait ? p.wait.exit_code.to_i64 : p.pid
		if run_as_user && run_as_password
			`xhost -si:localuser:#{user_str}`
		end
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
			open = true
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
		# 	thread.runner.display.gtk.act do
		# 		print_op = ::Gtk::PrintOperation.new
		# 		print_op.run ::Gtk::PrintOperationAction::PRINT_DIALOG, nil
		#		success = ...
		# 	end

		if edit
			success, stdout, stderr = try_execute(thread, "gtk-launch '#{`xdg-mime query default text/plain`.strip}' '#{target_raw}'", chdir: pwd, stdout: !!output_stdout, stderr: !!output_stderr)
		end

		if ! thread.runner.settings.run_as_user
			thread.runner.display.gtk.act do
				begin
					if target.starts_with?("www.")
						target = "http://#{target}"
					end
					# works for uris etc., but not for local files
					success = ::Gio.app_info_launch_default_for_uri(target, nil)
				rescue
				end
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

		error_level = nil
		if opt["useerrorlevel"]?
			error_level = success ? "0" : "ERROR"
		else
			if ! success
				raise ::Run::RuntimeException.new "Failed attempt to launch program or document: #{target}"
			elsif @wait
				error_level = success.to_s
			end
		end
		if error_level
			thread.set_thread_built_in_static_var("ErrorLevel", error_level)
			{% if ! flag?(:release) %}
				puts "[debug] ErrorLevel[#{thread.id}][Run]: #{error_level}"
			{% end %}
		end

		if output_var_pid && ! output_var_pid.empty? && ! @wait && success.is_a?(Int64)
			thread.runner.set_user_var(output_var_pid, success.to_s)
		end
	end
end