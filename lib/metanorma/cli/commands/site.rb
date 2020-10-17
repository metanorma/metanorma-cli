require "pathname"
require "metanorma/cli/site_generator"

module Metanorma
  module Cli
    module Commands
      class Site < Thor
        desc "site generate SOURCE_PATH", "Geneate site from collection"
        option :config, aliases: "-c", desc: "The metanorma configuration file"
        option(
          :output_dir,
          aliases: "-o",
          default: Pathname.new(Dir.pwd).join("site"),
          desc: "Output directory for the generated site",
        )

        def generate(source_path)
          Cli::SiteGenerator.generate(source_path, options.dup)
          UI.say("Site has been generated at #{options[:output_dir]}")
        rescue Cli::Errors::InvalidManifestFileError
          UI.error("Invalid data in: #{options[:config]}")
        end
      end
    end
  end
end
