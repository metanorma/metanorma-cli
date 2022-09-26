require "yaml"

module Metanorma
  module Cli
    class Collection
      def initialize(file, options)
        @file = file
        @options = Cli.with_indifferent_access(options)
        @compile_options = @options.delete(:compile)
      end

      def self.render(filename, options = {})
        new(filename, options).render
      end

      def render
        extract_options_from_file
        collection_file.render(collection_options.compact)
      end

      private

      attr_reader :file, :options

      def collection_file
        @collection_file ||= Metanorma::Collection.parse(file)
      end

      def source_folder
        @source_folder ||= File.dirname(File.expand_path(file))
      end

      def collection_options
        @collection_options ||= {
          compile: @compile_options,
          coverpage: options.fetch(:coverpage, nil),
          output_folder: options.fetch(:output_folder, source_folder),
          format: collection_output_formats(options.fetch(:format, "")),
        }
      end

      def collection_output_formats(formats)
        if formats.is_a?(String)
          formats = formats.split(",")
        end

        (formats || []).map { |extension| extension.strip.to_sym }
      end

      def extract_options_from_file
        if options.empty?
          yaml_file = YAML.safe_load(File.read(@file.to_s))

          @options = Cli.with_indifferent_access(
            yaml_file.slice("coverpage", "format", "output_folder"),
          )
        end
      end
    end
  end
end
