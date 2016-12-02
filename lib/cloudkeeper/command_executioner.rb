module Cloudkeeper
  class CommandExecutioner
    class << self
      def execute(*args)
        command = Mixlib::ShellOut.new(*args)
        logger.debug("Executing command: #{command.command.inspect}")
        command.run_command

        if command.error?
          raise Cloudkeeper::Errors::CommandExecutionError, "Command #{command.command.inspect} terminated with an error: " \
                                                            "#{command.stderr}"
        end

        command.stdout
      end

      def list_archive(archive)
        execute('tar', '-t', '-f', archive).lines.map(&:chomp)
      end
    end
  end
end
