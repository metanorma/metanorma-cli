# frozen_string_literal: true

require "metanorma"
require "metanorma/flavor"
require "metanorma/site_manifest"

module Metanorma
  module Cli
    autoload :Collection, "metanorma/cli/collection"
    autoload :Command, "metanorma/cli/command"
    autoload :Commands, "metanorma/cli/commands"
    autoload :Compiler, "metanorma/cli/compiler"
    autoload :ConfigExporter, "metanorma/cli/config_exporter"
    autoload :Errors, "metanorma/cli/errors"
    autoload :FlavorMethods, "metanorma/cli/flavor"
    autoload :Generator, "metanorma/cli/generator"
    autoload :GitTemplate, "metanorma/cli/git_template"
    autoload :SiteGenerator, "metanorma/cli/site_generator"
    autoload :TemplateRepo, "metanorma/cli/template_repo"
    autoload :ThorWithConfig, "metanorma/cli/thor_with_config"
    autoload :UI, "metanorma/cli/ui"
    autoload :VERSION, "metanorma/cli/version"

    CONFIG_DIRNAME = ".metanorma"
    CONFIG_FILENAME = "config.yml"

    def self.load_flavors
      Metanorma::Flavor.load_flavors
    end

    def self.start(arguments)
      if find_command(arguments).empty?
        arguments.unshift("compile")
      end

      Metanorma::Cli::Command.start(arguments)
    rescue SignalException # `Interrupt` inherits from this
      UI.say("Process cancelled, exiting.")
    rescue Errors::FileNotFoundError => e
      UI.say("Error: #{e}. \nNot sure what to run? try: metanorma help")
      exit(Errno::ENOENT::Errno)
    rescue Errors::FatalCompilationError => e
      print_fatal_summary(e)
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

    def self.config_path(global: false)
      return global_config_path if global

      local_config_path
    end

    def self.writable_templates_path?
      parent_directory = templates_path.join("..", "..")

      unless parent_directory&.writable?
        raise Errno::EACCES, "No permission to write in this directory"
      end

      true
    end

    def self.root_path
      Pathname.new(Cli.root).join("..")
    end

    def self.with_indifferent_access(options)
      Thor::CoreExt::HashWithIndifferentAccess.new(options)
    end

    def self.find_command(arguments)
      commands = Metanorma::Cli::Command.all_commands.keys
      commands.select { |cmd| arguments.include?(cmd.tr("_", "-")) == true }
    end

    def self.print_fatal_summary(error)
      $stdout.flush
      $stderr.flush
      UI.error(error.message)
      exit(-1)
    end
  end
end
