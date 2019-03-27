require "thor"
require "metanorma/cli/generator"

module Metanorma
  module Cli
    class Command < Thor
      desc "new NAME", "Create new Metanorma document"
      option :type, aliases: "-t", required: true, desc: "Document type"
      option :doctype, aliases: "-d", required: true, desc: "Metanorma doctype"
      option :overwrite, aliases: "-r", desc: "Overwrite existing document"

      def new(document_name)
        Metanorma::Cli::Generator.run(document_name, options)
      end
    end
  end
end
