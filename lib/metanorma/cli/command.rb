require "metanorma/cli/compiler"
require "metanorma/cli/generator"
require "metanorma/cli/git_template"
require "metanorma/cli/thor_with_config"
require "metanorma/cli/commands/config"
require "metanorma/cli/commands/template_repo"
require "metanorma/cli/commands/site"
require "metanorma/cli/collection_parser"

module Metanorma
  module Cli
    class Command < ThorWithConfig
      class_option :no_progress, aliases: "-s", type: :boolean, default: true,
                                 desc: "Don't show progress for long running tasks (like download)"

      desc "new NAME", "Create new Metanorma document"
      option :type, aliases: "-t", required: true, desc: "Document type"
      option :doctype, aliases: "-d", required: true, desc: "Metanorma doctype"
      option :overwrite, aliases: "-y", type: :boolean, desc: "Overwrite existing document"
      option :template, aliases: "-l", desc: "Git hosted remote or local FS template skeleton"

      def new(name)
        create_new_document(name, options)
      end

      desc "compile FILENAME", "Compile to a metanorma document"
      option :type, aliases: "-t", desc: "Type of standard to generate"
      option :extensions, aliases: "-x", type: :string, desc: "Type of extension to generate per type"
      option :format, aliases: "-f", default: :asciidoc, desc: "Format of source file: eg. asciidoc"
      option :require, aliases: "-r", desc: "Require LIBRARY prior to execution"
      option :wrapper, aliases: "-w", type: :boolean, desc: "Create wrapper folder for HTML output"
      option :asciimath, aliases: "-a", type: :boolean, desc: "Keep Asciimath in XML output instead of converting it to MathM"
      option :datauriimage, aliases: "-d", type: :boolean, desc: "Encode HTML output images as data URIs"
      option :relaton, aliases: "-R", desc: "Export Relaton XML for document to nominated filename"
      option :extract, aliases: "-e", desc: "Export sourcecode fragments from this document to nominated directory"
      option :version, aliases: "-v", desc: "Print version of code (accompanied with -t)"
      option :output_dir, aliases: "-o", desc: "Directory to save compiled files"
      option :agree_to_terms, type: :boolean, desc: "Agree / Disagree with all third-party licensing terms "\
                                                    "presented (WARNING: do know what you are agreeing with!)"
      option :no_install_fonts, type: :boolean, desc: "Skip the font installation process"
      option :continue_without_fonts, type: :boolean, desc: "Continue processing even when fonts are missing"

      def compile(file_name = nil)
        if file_name && !options[:version]
          documents = select_wildcard_documents(file_name) || [file_name]
          documents.each { |document| compile_document(document, options.dup) }

        elsif options[:version]
          invoke(:version, [], type: options[:type], format: options[:format])

        elsif options.keys.size >= 2
          UI.say("Need to specify a file to process")

        else
          invoke :help
        end
      end

      desc "collection FILENAME", "Render HTML pages from XML/YAML colection"
      option :format, aliases: "-x", type: :string, desc: "Formats to generate"
      option :output_folder, aliases: "-w", required: true, desc: "Directory to save compiled files"
      option :coverpage, aliases: "-c", desc: "Liquid template"
      option :agree_to_terms, type: :boolean, desc: "Agree / Disagree with all third-party licensing terms "\
                                                    "presented (WARNING: do know what you are agreeing with!)"
      option :no_install_fonts, type: :boolean, desc: "Skip the font installation process"
      option :continue_without_fonts, type: :boolean, desc: "Continue processing even when fonts are missing"

      def collection(filename = nil)
        if filename
          opts = options
          opts[:format] &&= opts[:format].split(",").map &:to_sym
          opts[:compile] = filter_compile_options(opts)
          coll = Metanorma::Collection.parse filename
          coll.render opts
        else UI.say("Need to specify a file to process")
        end
      rescue ArgumentError => e
        UI.say e.message
      end

      desc "version", "Version of the code"
      option :type, aliases: "-t", required: false, desc: "Type of standard to generate"
      option :format, aliases: "-f", default: :asciidoc, desc: "Format of source file: eg. asciidoc"

      def version
        Metanorma::Cli.load_flavors
        backend_version(options[:type]) || supported_backends
      rescue NameError => error
        UI.say(error)
      end

      desc "list-extensions", "List supported extensions"
      def list_extensions(type = nil)
        single_type_extensions(type) || all_type_extensions
      rescue LoadError
        UI.say("Couldn't load #{type}, please provide a valid type!")
      end

      desc "list-doctypes", "List supported doctypes"
      def list_doctypes(type = nil)
        processors = backend_processors

        if type && processors[type.to_sym]
          processors = { type.to_sym => processors[type.to_sym] }
        end

        print_doctypes_table(processors)
      end

      desc "template-repo", "Manage metanorma templates repository"
      subcommand :template_repo, Metanorma::Cli::Commands::TemplateRepo

      desc "site", "Manage site for metanorma collections"
      subcommand :site, Metanorma::Cli::Commands::Site

      desc "config", "Manage configuration file"
      subcommand :config, Metanorma::Cli::Commands::Config

      private

      def single_type_extensions(type)
        return false unless type

        format_keys = find_backend(type).output_formats.keys
        UI.say("Supported extensions: #{join_keys(format_keys)}.")
        true
      end

      def all_type_extensions
        Metanorma::Cli.load_flavors

        message = "Supported extensions per type: \n"
        Metanorma::Registry.instance.processors.each do |type_sym, processor|
          format_keys = processor.output_formats.keys
          message += "  #{type_sym}: #{join_keys(format_keys)}.\n"
        end

        UI.say(message)
      end

      def backend_version(type)
        if type
          UI.say(find_backend(type).version)
        end
      end

      def backend_processors
        @backend_processors ||= (
          Metanorma::Cli.load_flavors
          Metanorma::Registry.instance.processors
        )
      end

      def find_backend(type)
        load_flavours(type)
        Metanorma::Registry.instance.find_processor(type&.to_sym)
      end

      def supported_backends
        UI.say("Metanorma #{Metanorma::VERSION}")
        UI.say("Metanorma::Cli #{VERSION}")

        Metanorma::Cli.load_flavors

        Metanorma::Registry.instance.processors.map do |type, processor|
          UI.say(processor.version)
        end
      end

      def join_keys(keys)
        [keys[0..-2].join(", "), keys.last].join(" and ")
      end

      def create_new_document(name, options)
        Metanorma::Cli::Generator.run(
          name,
          type: options[:type],
          doctype: options[:doctype],
          template: options[:template],
          overwrite: options[:overwrite],
        )
      end

      def load_flavours(type)
        Metanorma::Cli.load_flavors
        unless Metanorma::Registry.instance.find_processor(type&.to_sym)
          require "metanorma-#{type}"
        end
      end

      def print_doctypes_table(processors)
        table_data = processors.map do |type_sym, processor|
          [
            type_sym.to_s,
            processor.input_format,
            join_keys(processor.output_formats.keys),
          ]
        end

        UI.table(["Type", "Input", "Supported output format"], table_data)
      end

      def select_wildcard_documents(filename)
        if filename.include?("*")
          Dir.glob(Pathname.new(filename))
        end
      end

      def compile_document(filename, options)
        Metanorma::Cli.load_flavors
        errors = Metanorma::Cli::Compiler.compile(filename, options)
        errors.each { |error| Util.log(error, :error) }

        exit(1) if errors.any?
      end
    end
  end
end
