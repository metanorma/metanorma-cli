module Metanorma
  module Cli
    module Commands
      class Site < Thor
        desc "site cleanup", "Cleanup site generated outputs"
        def cleanup
          UI.say("@TODO: Cleanup all generated resources")
        end
      end
    end
  end
end
