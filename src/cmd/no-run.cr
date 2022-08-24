module NoRun
	def self.min_args; 0 end
	def self.max_args; 0 end
	def run(thread, args)
		raise Run::RuntimeException.new "Base '#{self.class.name}' cannot be run"
	end
end