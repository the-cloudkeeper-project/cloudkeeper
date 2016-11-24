module Cloudkeeper
  class CommandExecutioner
    class << self
      def execute(*args)
        command = Mixlib::ShellOut.new(*args)
        command.run_command

        if command.error?
          raise Cloudkeeper::Errors::CommandExecutionError, "Command #{command.command.inspect} terminated with an error: " \
                                                            "#{command.stderr}"
        end

        command.stdout
      end
    end
  end
end
