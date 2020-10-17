require "metanorma/cli/site_generator"

module Metanorma
  module Cli
    module Commands
      class Site < Thor
        desc "site cleanup", "Cleanup site generated outputs"
        def cleanup
          UI.say("@TODO: Cleanup all generated resources")
        end

        desc "site generate SOURCE_PATH", "Geneate site from collection"
        def generate(source_path)
          Cli::SiteGenerator.generate(source_path, options)
        end
      end
    end
  end
end
