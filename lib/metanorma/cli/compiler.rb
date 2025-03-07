require "pathname"
require "metanorma/cli/errors"

module Metanorma
  module Cli
    class Compiler
      def initialize(file, options)
        validate_file_path(file)
        @file = file
        @options = options
        normalize_special_options
      end

      def validate_file_path(file)
        path = Pathname.new(file)
        # Check if provided file path exists
        unless path.exist?
          raise ::Metanorma::Cli::Errors::FileNotFoundError.new(
            "Specified input file '#{file}' does not exist",
          )
        end

        # Check if provided file is really a file
        unless path.file?
          raise ::Metanorma::Cli::Errors::FileNotFoundError.new(
            "Specified input file '#{file}' is not a file",
          )
        end
      end

      # @return [Array<String>]
      def compile
        compile_file
      end

      # @return [Array<String>]
      def self.compile(file, options)
        new(file, options).compile
      end

      private

      attr_reader :file, :options, :extract, :extensions

      # @return [Array<String>]
      def compile_file
        c = Compile.new
        c.compile(file, serialize_options)
        c.errors
      end

      def serialize_options
        serialize(options.merge(customize_options))
      end

      def customize_options
        extract_option.merge(extension_option)
      end

      def extract_option
        Hash.new.tap do |hash|
          hash[:extract] = extract[0]
          hash[:extract_type] =
            extract.empty? ? [] : extract.map(&:to_sym)
        end
      end

      def extension_option
        extensions.empty? ? {} : { extension_keys: extensions.map(&:to_sym) }
      end

      def serialize(options)
        Hash.new.tap do |hash|
          options.each do |key, value|
            hash[key.to_sym] = value unless value.nil?
          end
        end
      end

      def normalize_special_options
        @extract = (options.delete(:extract) || "").split(",")
        @extensions = (options.delete(:extensions) || "").split(",")
        options[:require] = [options[:require]] if options[:require]
      end
    end
  end
end
