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
      #"metanorma-gb",
      "metanorma-bipm",
      "metanorma-cc",
      "metanorma-csa",
      "metanorma-iho",
      "metanorma-m3aawg",
      "metanorma-generic",
      "metanorma-standoc",
      "metanorma-un",
      "metanorma-nist",
      "metanorma-ogc",
      "metanorma-itu",
    ]

    CONFIG_DIRNAME = ".metanorma"
    CONFIG_FILENAME = "config.yml"

    PRIVATE_SUPPORTED_GEMS = ["metanorma-ribose", "metanorma-mpfa"]

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
      Pathname.new(Dir.home).join(CONFIG_DIRNAME)
    end

    def self.global_config_path
      home_directory.join(CONFIG_FILENAME)
    end

    def self.local_config_path
      Pathname.new(Dir.pwd).join(CONFIG_DIRNAME, CONFIG_FILENAME)
    end

    def self.config_path(global=false)
      return global_config_path if global
      return local_config_path
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
