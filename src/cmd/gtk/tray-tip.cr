# TrayTip [, Title, Text, Seconds, Options]
class Cmd::Gtk::Gui::TrayTip < Cmd::Base
	def self.min_args; 0 end
	def self.max_args; 4 end
	class_property notifications = [] of Notify::Notification
	def run(thread, args)
		if args.size < 2
			thread.runner.display.gtk.act do
				@@notifications.each &.close
			end
			@@notifications.clear
			return
		end
		icon = case args[3]?
		when nil then nil
		when "1" then "dialog-information"
		when "2" then "dialog-warning"
		when "3" then "dialog-error"
		else nil end
		timeout = args[2]? && args[2].to_f?
		gtk_notification = thread.runner.display.gtk.act do
        	notification = Notify::Notification.new(args[0], args[1], icon)
			notification.timeout = (timeout.to_f * 1000).to_i if timeout
        	notification.show()
			notification
		end
		@@notifications << gtk_notification
	end
end