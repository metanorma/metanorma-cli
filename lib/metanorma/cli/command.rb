require "thor"
require "metanorma/cli/compiler"
require "metanorma/cli/generator"
require "metanorma/cli/git_template"
require "metanorma/cli/commands/template_repo"

module Metanorma
  module Cli
    class Command < Thor
      desc "new NAME", "Create new Metanorma document"
      option :type, aliases: "-t", required: true, desc: "Document type"
      option :doctype, aliases: "-d", required: true, desc: "Metanorma doctype"
      option :overwrite, aliases: "-y", type: :boolean, desc: "Overwrite existing document"
      option :template, aliases: "-l", desc: "Git hosted remote or local FS template skeleton"

      def new(name)
        create_new_document(name, options.dup)
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

      def compile(file_name = nil)
        if file_name && !options[:version]
          Metanorma::Cli::Compiler.compile(file_name, options.dup)

        elsif options[:version]
          invoke(:version, [], type: options[:type] || :iso, format: options[:format])

        elsif options.keys.size >= 2
          UI.say("Need to specify a file to process")

        else
          invoke :help
        end
      end

      desc "version", "Version of the code"
      option :type, aliases: "-t", required: true, desc: "Type of standard to generate"
      option :format, aliases: "-f", default: :asciidoc, desc: "Format of source file: eg. asciidoc"

      def version
        if options[:format] == :asciidoc
          UI.say(find_backend(options[:type].to_sym).version)
        end
      end

      desc "list-extensions", "List supported extensions"
      def list_extensions(type = nil)
        single_type_extensions(type) || all_type_extensions
      rescue LoadError
        UI.say("Couldn't load #{type}, please provide a valid type!")
      end

      desc "template-repo", "Manage metanorma templates repository"
      subcommand :template_repo, Metanorma::Cli::Commands::TemplateRepo

      private

      def single_type_extensions(type)
        if type
          format_keys = find_backend(type).output_formats.keys
          UI.say("Supported extensions: #{join_keys(format_keys)}.")
          return true
        end
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

      def find_backend(type)
        require "metanorma-#{type}"
        Metanorma::Registry.instance.find_processor(type.to_sym)
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
    end
  end
end
