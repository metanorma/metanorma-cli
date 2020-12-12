module Metanorma
  module Cli
    module Errors
      class DuplicateTemplateError < StandardError; end

      class FileNotFoundError < StandardError; end
      class InvalidManifestFileError < StandardError; end
    end
  end
end
