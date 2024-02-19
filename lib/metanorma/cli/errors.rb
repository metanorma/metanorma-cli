module Metanorma
  module Cli
    module Errors
      class DuplicateTemplateError < StandardError; end

      class FileNotFoundError < StandardError; end
      class InvalidManifestFileError < StandardError; end

      class FatalCompilationError < StandardError
        attr_reader :fatals

        def initialize(fatals)
          super()
          @fatals = fatals
        end

        def message
          <<~MSG
            Fatal compilation error(s):
            #{fatals.map { |f| "- #{f}" }.join("\n")}

            Look at error.log for more details
          MSG
        end
      end
    end
  end
end
