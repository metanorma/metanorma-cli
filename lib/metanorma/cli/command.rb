require "thor"
require "metanorma/cli/compiler"
require "metanorma/cli/generator"
require "metanorma/cli/git_template"

module Metanorma
  module Cli
    class Command < Thor
      desc "new NAME", "Create new Metanorma document"
      option :type, aliases: "-t", required: true, desc: "Document type"
      option :doctype, aliases: "-d", required: true, desc: "Metanorma doctype"
      option :overwrite, aliases: "-r", desc: "Overwrite existing document"
      option :template, aliases: "-l", desc: "Git hosted remote or local FS template skeleton"

      def new(name)
        create_new_document(name, options.dup)
      end

      desc "compile FILENAME", "Compile to a metanorma document"
      option :type, aliases: "-t", desc: "Type of standard to generate"
      option :extensions, aliases: "-x", type: :string, desc: "Type of extension to generate per type"
      option :format, aliases: "-f", default: :asciidoc, desc: "Format of source file: eg. asciidoc"
      option :require, aliases: "-r", type: :array, desc: "Require LIBRARY prior to execution"
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
          UI.say(find_version(options[:type]))
        end
      end

      private

      def find_version(type)
        require "metanorma-#{type}"
        processor = Metanorma::Registry.instance.find_processor(type.to_sym)
        processor.version
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
