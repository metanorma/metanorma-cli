# frozen_string_literal: true

require "metanorma/cli/compiler"
require "metanorma/cli/generator"
require "metanorma/cli/collection"
require "metanorma/cli/git_template"
require "metanorma/cli/thor_with_config"
require "metanorma/cli/commands/config"
require "metanorma/cli/commands/template_repo"
require "metanorma/cli/commands/site"
require "mnconvert"
require_relative "flavor"

module Metanorma
  module Cli
    class Command < ThorWithConfig
      class_option :progress, aliases: "-s", type: :boolean, default: false,
                              desc: "Show progress for long running tasks" \
                                    " (like download)"

      desc "new NAME", "Create new Metanorma document"
      option :type, aliases: "-t", required: true, desc: "Document type"
      option :doctype, aliases: "-d", required: true, desc: "Metanorma doctype"
      option :overwrite, aliases: "-y", type: :boolean,
                         desc: "Overwrite existing document"
      option :template, aliases: "-l",
                        desc: "Git hosted remote or local FS template skeleton"

      def new(name)
        create_new_document(name, options)
      end

      desc "compile FILENAME", "Compile to a metanorma document"
      option :type, aliases: "-t", desc: "Type of standard to generate"
      option :extensions, aliases: "-x", type: :string,
                          desc: "Type of extension to generate per type"
      option :format, aliases: "-f", default: :asciidoc,
                      desc: "Format of source file: eg. asciidoc"
      option :require, aliases: "-r", desc: "Require LIBRARY prior to execution"
      option :wrapper, aliases: "-w", type: :boolean,
                       desc: "Create wrapper folder for HTML output"
      option :asciimath, aliases: "-a", type: :boolean,
                         desc: "Keep Asciimath in XML output instead of" \
                               " converting it to MathM"
      option :datauriimage, aliases: "-d", type: :boolean,
                            desc: "Encode HTML output images as data URIs"
      option :relaton, aliases: "-R",
                       desc: "Export Relaton XML for document to nominated" \
                             " filename"
      option :extract, aliases: "-e",
                       desc: "Export sourcecode fragments from this document" \
                             " to nominated directory"
      option :version, aliases: "-v",
                       desc: "Print version of code (accompanied with -t)"
      option :log_messages, aliases: "-L",
                            desc: "Display available log messages " \
                            "(accompanied with -t)"
      option :output_dir, aliases: "-o",
                          desc: "Directory to save compiled files"
      option :strict, aliases: "-S", type: :boolean,
                      desc: "Strict compilation: abort if there are any errors"
      option :agree_to_terms,
             type: :boolean,
             desc: "Agree / Disagree with all third-party licensing terms "\
                   "presented (WARNING: do know what you are agreeing with!)"
      option :install_fonts, type: :boolean, default: true,
                             desc: "Install required fonts"
      option :continue_without_fonts,
             type: :boolean,
             desc: "Continue processing even when fonts are missing"

      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      def compile(file_name = nil)
        if file_name && !options[:version]
          documents = select_wildcard_documents(file_name) || [file_name]
          documents.each { |document| compile_document(document, options.dup) }

        elsif options[:version]
          invoke(:version, [], type: options[:type], format: options[:format])

        elsif options[:log_messages]
          invoke(:log_messages, [], type: options[:type], agree_to_terms: true)

        elsif options.keys.size >= 2
          UI.say("Need to specify a file to process")

        else
          invoke :help
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/PerceivedComplexity

      desc "collection FILENAME", "Render HTML pages from XML/YAML colection"
      option :format, aliases: "-x", type: :string, desc: "Formats to generate"
      option :output_folder, aliases: "-w",
                             desc: "Directory to save compiled files"
      option :coverpage, aliases: "-c", desc: "Liquid template"
      option :agree_to_terms,
             type: :boolean,
             desc: "Agree / Disagree with all third-party licensing terms "\
                   "presented (WARNING: do know what you are agreeing with!)"
      option :install_fonts, type: :boolean, default: true,
                             desc: "Install required fonts"
      option :continue_without_fonts,
             type: :boolean,
             desc: "Continue processing even when fonts are missing"
      option :strict, aliases: "-S", type: :boolean, \
                      desc: "Strict compilation: abort if there are any errors"

      def collection(filename = nil)
        if filename
          coll_options = options.dup
          coll_options[:compile] = filter_compile_options(coll_options)
          Metanorma::Cli::Collection.render(filename, coll_options)
        else
          UI.say("Need to specify a file to process")
        end
      rescue ArgumentError => e
        UI.say e.message
      end

      desc "convert FILENAME", "Convert STS XML to Metanorma adoc"
      option :output_format,
             type: :string,
             desc: "Output format: xml|adoc|iso|niso"
      option :output_file, type: :string, desc: "Output file"
      option :imagesdir,
             type: :string,
             desc: "For STS input only: folder with images"
      option :input_format,
             type: :string,
             desc: "Input format: metanorma|sts|rfc"
      option :debug, type: :boolean, desc: "Enable debug output"
      option :sts_type,
             type: :string,
             desc: "For STS input only: type of standard to generate"
      option :check_type, type: :string, desc: "Check against XSD/DTD"
      option :xsl_file, type: :string, desc: "Path to XSL file"
      option :split_bibdata,
             type: :boolean,
             desc: "For STS input only: create MN Adoc and Relaton XML"
      option :semantic,
             type: :boolean,
             desc: "For STS input only: generate semantic XML"

      def convert(inputfile)
        MnConvert.convert(inputfile, options)
      rescue Error => e
        UI.say e.message
      end

      desc "version", "Version of the code"
      option :type, aliases: "-t", required: false,
                    desc: "Type of standard to generate"
      option :format, aliases: "-f", default: :asciidoc,
                      desc: "Format of source file: eg. asciidoc"

      def version
        Metanorma::Cli.load_flavors
        backend_version(options[:type]) || supported_backends
        options[:type] or dependencies_versions
      rescue NameError => e
        UI.say(e)
      end

      desc "log_messages", "Display available log messages for a standard type"
      option :type, aliases: "-t", required: false,
                    desc: "Type of standard to generate"

      def log_messages
        if options[:type]
          Metanorma::Cli.load_flavors
          messages = ::Metanorma::Compile.new.extract_log_messages(options[:type])
          UI.say(messages)
        else
          UI.say("Please specify a standard type with -t option")
        end
      rescue NameError => e
        UI.say(e)
      end

      desc "list-extensions", "List supported extensions"
      def list_extensions(type = nil)
        single_type_extensions(type) || all_type_extensions
      end

      desc "list-doctypes", "List supported doctypes"
      def list_doctypes(type = nil)
        print_doctypes_table(type)
      end

      desc "export-config", "Export flvor configuration"
      def export_config(type = nil)
        export_config_flavor(type)
      end

      desc "template-repo", "Manage metanorma templates repository"
      subcommand :template_repo, Metanorma::Cli::Commands::TemplateRepo

      desc "site", "Manage site for metanorma collections"
      subcommand :site, Metanorma::Cli::Commands::Site

      desc "config", "Manage configuration file"
      subcommand :config, Metanorma::Cli::Commands::Config

      def self.exit_on_failure?
        true
      end
    end
  end
end
