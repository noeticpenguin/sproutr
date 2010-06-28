module Stem
  module CLI
    extend self

    Version = 0.1

    # Return a structure describing the options.
    def parse_options(args)
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: stem COMMAND ..."

        opts.separator " "

        opts.separator "Examples:"
        opts.separator "  $ stem boot prototype.config prototype.sh"
        opts.separator "  $ stem list"
        opts.separator "  $ stem image instance-id class-name"

        opts.separator " "
        opts.separator "Options:"

        opts.separator "Common Options:"

        opts.on("-v", "--version", "Print the version") do |v|
          puts "Stem v#{Stem::Version}"
          exit
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end

      opts.separator ""

      opts.parse!(args)
    end

    def dispatch_command command, arguments
      case command
        when "launch"
          launch(*arguments)
        when "capture"
          capture(*arguments)
        when "list"
          list(*arguments)
        when nil
          puts "Please provide a command."
        else
          puts "Command \"#{command}\" not recognized."
      end
    end

    def launch config_file = nil, userdata_file = nil
      throw "No config file" unless config_file
      userdata = File.new(userdata_file).read() if userdata_file
      instance = Stem::launch(JSON.parse(File.new(config_file).read()), userdata)
      puts "New instance ID: #{instance}"
    end

    def capture name = nil, instance = nil
      throw "Usage: capture ami-name instance-to-capture" unless name && instance
      Stem::capture(name, instance)
    end

    def list *arguments
      Stem::list(*arguments)
    end
  end
end

