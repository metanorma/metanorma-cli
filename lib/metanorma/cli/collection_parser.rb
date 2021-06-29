require "yaml"

module Metanorma
  module Cli
    class CollectionParser
      def initialize(collection_file)
        @collection_file = collection_file
      end

      def self.parse(collection_file)
        new(collection_file).parse
      end

      def parse
        # extract out the options
        options = extract_options(yaml_content)
        # load the file
        metanorma_collection.render(options)

        # pass it down to metanorma
      end

      private

      attr_reader :collection_file

      def yaml_content
        @yaml_content ||= YAML.load(File.read(collection_file.to_s))
      end

      def metanorma_collection
        @metanorma_collection ||= Metanorma::Collection.parse(collection_file)
      end

      def extract_options(content_hash)
        Hash.new.tap do |options|
          options[:coverpage] = content_hash["cover"]
          options[:output_folder] = content_hash["output_dir"]
          options[:format] = content_hash["formats"].map(&:to_sym)
        end
      end
    end
  end
end
