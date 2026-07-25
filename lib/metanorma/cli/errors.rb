module Metanorma
  module Cli
    module Errors
      class DuplicateTemplateError < StandardError; end

      class FileNotFoundError < StandardError; end
      class InvalidManifestFileError < StandardError; end

      class FatalCompilationError < StandardError
        def initialize(fatals)
          @fatals = fatals
          super(format_message(fatals))
        end

        attr_reader :fatals

        private

        def format_message(fatals)
          "Fatal compilation error(s):\n" \
            "#{fatals.map { |f| "- #{f}" }.join("\n")}\n" \
            "Look at error.log for more details"
        end
      end
    end
  end
end
