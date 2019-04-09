module Metanorma
  module Cli
    class Compiler
      def initialize(file, options)
        @file = file
        @options = options
        @extract = options.delete(:extract) || []

        # extensions are given as "html,pdf,doc,xml", need to split them
        @extensions = (options.delete(:extensions) || "").split(',')
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
        Metanorma::Compile.new.compile(
          file,
          options.merge(customize_options),
        )
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
        extensions ? { extension_keys: extensions.map(&:to_sym) } : {}
      end
    end
  end
end
