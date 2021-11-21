module Metanorma
  module Cli
    class Collection
      def initialize(file, options)
        @file = file
        @options = options
      end

      def self.render(filename, options = {})
        new(filename, options).render
      end

      def render
        collection_file.render(collection_options)
      end

      private

      attr_reader :file, :options

      def collection_file
        @collection_file ||= Metanorma::Collection.parse(file)
      end

      def collection_options
        {
          compile: options.fetch(:compile, nil),
          coverpage: options.fetch("coverpage", nil),
          output_folder: options.fetch("output_folder", nil),
          format: collection_output_formats(options.fetch("format", "")),
        }
      end

      def collection_output_formats(format)
        format.split(",")&.map(&:to_sym)
      end
    end
  end
end
