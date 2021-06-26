require "yaml"

module Metanorma
  module Cli
    class CollectionParser
      def initialize(collection_file, options = {})
        @options = options
        @collection_file = collection_file.to_s
      end

      def self.parse(collection_file, options = {})
        new(collection_file, options).parse
      end

      def parse
        # puts merged_options(extract_options(yaml_content), options)
        # puts options
        # puts extract_options(yaml_content)

        # extract out the options
        # options = extract_options(yaml_content)
        # puts options

        # require "pry"
        # binding.pry

        # load the file
        # metanorma_collection.render(options)

        # pass it down to metanorma
      end

      def merged_options(base_options, prefered_options)
        base_options.merge(prefered_options)
      end

      private

      attr_reader :collection_file, :options

      def yaml_content
        @yaml_content ||= YAML.safe_load(File.read(collection_file))
      end

      def metanorma_collection
        @metanorma_collection ||= Metanorma::Collection.parse(collection_file)
      end

      def extract_options(content_hash)
        Hash.new.tap do |options|
          options["coverpage"] ||= content_hash["cover"]
          options["output_folder"] ||= content_hash["output_dir"]
          options["format"] ||= content_hash["formats"]&.map(&:to_sym)
        end
      end
    end
  end
end
