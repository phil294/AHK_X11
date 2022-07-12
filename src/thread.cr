module Run
    # ahk threads are no real threads but pretty much like crystal fibers, except they're not
    # cooperative at all; they take each other's place (prioritized) and continue until their invididual end.
    class Thread
        getter runner : Runner
        @stack = [] of Cmd
        @exit_code = 0
        def initialize(@runner, start)
            @stack << start
        end

        protected def next
            ins = @stack.last?
            return @exit_code if ! ins
            stack_i = @stack.size - 1
            result = ins.run(self)
            next_ins = ins.next
            if ins.class.control_flow
                if result
                    next_ins = ins.je
                else
                    next_ins = ins.jne
                end
            end
            # current stack el may have been altered by prev ins.run(), in which case disregard the normal flow
            if @stack[stack_i]? == ins # not altered
                if ! next_ins
                    @stack.delete_at(stack_i)
                else
                    @stack[stack_i] = next_ins
                end
            end
            nil
        end

        def gosub(label)
            cmd = @runner.labels[label]?
            raise RuntimeException.new "gosub: label '#{label}' not found" if ! cmd
            @stack << cmd
        end
        def goto(label)
            cmd = @runner.labels[label]?
            raise RuntimeException.new "goto: label '#{label}' not found" if ! cmd
            @stack[@stack.size - 1] = cmd
        end
        def return
            @stack.pop
        end
        def exit(code)
            @exit_code = code || 0
            @stack.clear
        end
    end
end