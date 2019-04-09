module Metanorma
  module Cli
    class Compiler
      def initialize(file, options)
        @file = file
        @options = options
        @extract = (options.delete(:extract) || "").split(",")
        @extensions = (options.delete(:extensions) || "").split(",")
      end

      def compile
        compile_file
      end

      def self.compile(file, options)
        new(file, options).compile
      end

      private

      attr_reader :file, :options, :extract, :extensions

      def compile_file
        Compile.new.compile( file, serialize_options)
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
            extract.size > 0 ? extract[0..-1].map(&:to_sym) : []
        end
      end

      def extension_option
        !extensions.empty? ? { extension_keys: extensions.map(&:to_sym) } : {}
      end

      def serialize(options)
        Hash.new.tap do |hash|
          options.each do |key, value|
            hash[key.to_sym] = value unless value.nil?
          end
        end
      end
    end
  end
end
