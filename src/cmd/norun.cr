require "./cmd"

module NoRun
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(runner)
		raise RuntimeException.new "Cmd '#{self.class.name}' cannot be run"
	end
end