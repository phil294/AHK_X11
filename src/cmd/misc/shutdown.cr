# Shutdown, Code
class Cmd::Misc::Shutdown < Cmd::Base
	def self.min_args; 1 end
	def self.max_args; 1 end
	def run(thread, args)
		case args[0].to_i?
		when 0, 4 # logoff / force(ignored)
			`gnome-session-quit || mate-session-save --force-logout || xfce4-session-logout --logout || loginctl |grep -E -v "root|SESSION|listed" |awk '{print $1}' |xargs loginctl terminate-session || kill -9 -1 || sudo pkill -u username || sudo killall X`
		when 1, 8 # shut down, power off
			`halt --poweroff` # somehow needs no password, while `poweroff --halt` does. wtf.
		when 5, 12 # shut down, power off: force. Sudo first in case the user has sudoers NOPASSWD set.
			`sudo -S halt --poweroff --force || pkexec halt --poweroff --force || gksu halt --poweroff --force`
		when 2 # reboot
			`reboot`
		when 6 # reboot: force
			`sudo -S reboot --force || pkexec reboot --force || gksu reboot --force`
		end
	end
end