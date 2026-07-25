require "pathname"

module Metanorma
  module Cli
    class Compiler
      def initialize(file, options)
        @file = file
        @options = options
        validate_file_path
        normalize_special_options
      end

      def compile
        compile_file
      end

      def self.compile(file, options)
        new(file, options).compile
      end

      private

      attr_reader :file, :options, :extract, :extensions

      def validate_file_path
        path = Pathname.new(file)
        unless path.exist?
          raise Errors::FileNotFoundError,
                "Specified input file '#{file}' does not exist"
        end

        unless path.file?
          raise Errors::FileNotFoundError,
                "Specified input file '#{file}' is not a file"
        end
      end

      def compile_file
        c = Compile.new
        c.compile(file, serialize_options)
        c.errors
      rescue SystemExit => e
        raise Errors::FatalCompilationError, [e.message]
      end

      def serialize_options
        options.merge(customize_options).compact.transform_keys(&:to_sym)
      end

      def customize_options
        extract_option.merge(extension_option)
      end

      def extract_option
        {
          extract: extract.first,
          extract_type: extract.map(&:to_sym),
        }.compact
      end

      def extension_option
        return {} if extensions.empty?

        { extension_keys: extensions.map(&:to_sym) }
      end

      def normalize_special_options
        @extract = (options.delete(:extract) || "").split(",")
        @extensions = (options.delete(:extensions) || "").split(",")
        options[:require] = [options[:require]] if options[:require]
      end
    end
  end
end
