require "thor"
require "metanorma/cli/compiler"
require "metanorma/cli/generator"

module Metanorma
  module Cli
    class Command < Thor
      desc "new NAME", "Create new Metanorma document"
      option :type, aliases: "-t", required: true, desc: "Document type"
      option :doctype, aliases: "-d", required: true, desc: "Metanorma doctype"
      option :overwrite, aliases: "-r", desc: "Overwrite existing document"

      def new(document_name)
        Metanorma::Cli::Generator.run(document_name, options.dup)
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
        else
          invoke(:version, [], type: options[:type], format: options[:format])
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
    end
  end
end
