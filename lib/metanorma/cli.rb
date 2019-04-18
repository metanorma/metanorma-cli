require "metanorma"
require "metanorma/cli/version"
require "metanorma/cli/command"

module Metanorma
  module Cli

    SUPPORTED_GEMS = [
      "metanorma-iso",
      "metanorma-ietf",
      "metanorma-gb",
      "metanorma-csd",
      "metanorma-csand",
      "metanorma-m3d",
      "metanorma-rsd",
      "metanorma-acme",
      "metanorma-standoc",
      "metanorma-unece",
      "metanorma-mpfd",
      "metanorma-nist",
      "metanorma-ogc"
    ]

    def self.load_flavors(flavor_names = SUPPORTED_GEMS)
      flavor_names.each do |flavor|
        begin
          require flavor
        rescue LoadError
          $stderr.puts "[metanorma] Error: flavor gem #{flavor} not present"
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
    end

    def self.root
      File.dirname(__dir__)
    end

    def self.templates_path
      root_path.join("templates")
    end

    def self.root_path
      Pathname.new(Cli.root).join("..")
    end

    def self.find_command(arguments)
      commands = Metanorma::Cli::Command.all_commands.keys
      commands.select { |cmd| arguments.include?(cmd) == true }
    end
  end
end
