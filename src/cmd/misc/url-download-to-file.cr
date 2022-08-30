require "http/client"
class Cmd::Misc::URLDownloadToFile < Cmd::Base
	def self.min_args; 2 end
	def self.max_args; 2 end
	def self.sets_error_level; true end
	def run(thread, args)
		url, filename = args
		begin
			body = HTTP::Client.get(url).body
			::File.write(filename, body, mode: "w")
			"0"
		rescue
			"1"
		end
	end
end