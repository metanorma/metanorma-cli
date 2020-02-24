require "metanorma"
require "metanorma/cli/version"
require "metanorma/cli/errors"
require "metanorma/cli/command"

module Metanorma
  module Cli
    SUPPORTED_GEMS = [
      "metanorma-iso",
      "metanorma-iec",
      "metanorma-ietf",
      "metanorma-gb",
      "metanorma-csd",
      "metanorma-csa",
      "metanorma-m3d",
      "metanorma-acme",
      "metanorma-standoc",
      "metanorma-un",
      "metanorma-nist",
      "metanorma-ogc",
      "metanorma-itu"
    ]

    PRIVATE_SUPPORTED_GEMS = ["metanorma-rsd", "metanorma-mpfd"]

    def self.load_flavors(flavor_names = SUPPORTED_GEMS + PRIVATE_SUPPORTED_GEMS)
      flavor_names.each do |flavor|
        begin
          require flavor
        rescue LoadError
          unless PRIVATE_SUPPORTED_GEMS.include?(flavor)
            $stderr.puts "[metanorma] Error: flavor gem #{flavor} not present"
          end
        end
      end
    end

    def self.load_all_flavors
      flavor_names = Gem::Specification.find_all do |g|
        g.name =~ /\Ametanorma-.*\Z/
      end.map(&:name)

      load_flavors(flavor_names)
    end

    # Invoking commands
    #
    # In the Metanorma CLI, we've included some custom behavior,
    # like exposing the compiation directly from the root command.
    #
    # So, for this use case we first check if the user is actually
    # trying to compile a document or not, and based on that we'll
    # compile the document or show the help documentation.
    #
    def self.start(arguments)
      if find_command(arguments).empty?
        arguments.unshift("compile")
      end

      Metanorma::Cli::Command.start(arguments)

    rescue Errors::FileNotFoundError => error
      UI.say("Error: #{error}. \nNot sure what to run? try: metanorma help")
      exit(Errno::ENOENT::Errno)
    end

    def self.root
      File.dirname(__dir__)
    end

    def self.base_templates_path
      root_path.join("templates", "base")
    end

    def self.templates_path
      home_directory.join("templates")
    end

    def self.home_directory
      Pathname.new(Dir.home).join(".metanorma")
    end

    def self.writable_templates_path?
      parent_directory = templates_path.join("..", "..")

      unless parent_directory && parent_directory.writable?
        raise Errno::EACCES, "No permission to write in this directory"
      end

      return true
    end

    def self.root_path
      Pathname.new(Cli.root).join("..")
    end

    def self.find_command(arguments)
      commands = Metanorma::Cli::Command.all_commands.keys
      commands.select { |cmd| arguments.include?(cmd.gsub("_", "-")) == true }
    end
  end
end
