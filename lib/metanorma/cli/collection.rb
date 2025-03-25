require "yaml"

module Metanorma
  module Cli
    class Collection
      def initialize(file, options)
        @file = file
        @options = Cli.with_indifferent_access(options)
        @output_dir = @options.delete(:output_dir)
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
          output_folder: build_output_folder,
          coverpage: @options.fetch(:coverpage, nil),
          format: collection_output_formats(@options.fetch(:format, "")),
          site_generate: @options["site_generate"],
        }
      end

      def build_output_folder
        output_folder = options.fetch(:output_folder, nil)

        if output_folder && @output_dir
          @output_dir.join(output_folder).to_s
        else
          output_folder || source_folder
        end
      end

      def collection_output_formats(formats)
        if formats.is_a?(String)
          formats = formats.split(",")
        end

        (formats || []).map { |extension| extension.strip.to_sym }
      end

      def extract_options_from_file
        yaml_file = if /\.ya?ml$/.match?(@file.to_s)
                      YAML.safe_load(File.read(@file.to_s))
                    elsif /\.xml$/.match?(@file.to_s)
                      xml_extract_options_from_file
                    end

        old = options.dup
        @options = Cli.with_indifferent_access(
          yaml_file.slice("coverpage", "format", "output_folder"),
        )
        @options.merge!(old)
      end

      def xml_extract_options_from_file
        xml = Nokogiri::XML File.read(@file.to_s, encoding: "UTF-8", &:huge)
        { "coverpage" => xml.at("//coverpage"),
          "format" => xml.at("//format"),
          "output_folder" => xml.at("//output_folder") }.compact
      end
    end
  end
end
