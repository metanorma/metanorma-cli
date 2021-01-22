require "pathname"
require "metanorma/cli/site_generator"
require "metanorma/cli/thor_with_config"

module Metanorma
  module Cli
    module Commands
      class Site < ThorWithConfig
        desc "generate SOURCE_PATH", "Generate site from collection"
        option :config, aliases: "-c", desc: "Metanorma configuration file"
        option(
          :output_dir,
          aliases: "-o",
          default: Pathname.new(Dir.pwd).join("site").to_s,
          desc: "Output directory for generated site",
        )
        option :"agree-to-terms", type: :boolean, desc: "Agree / Disagree with all third-party licensing terms "\
                                                        "presented (WARNING: do know what you are agreeing with!)"
        option :"no-install-fonts", type: :boolean, desc: "Skip the font installation process"
        option :"continue-without-fonts", type: :boolean, desc: "Continue processing even when fonts are missing"

        def generate(source_path)
          opts = options.dup
          Cli::SiteGenerator.generate(source_path, opts, filter_compile_options(opts))
          UI.say("Site has been generated at #{options[:output_dir]}")
        rescue Cli::Errors::InvalidManifestFileError
          UI.error("Invalid data in: #{options[:config]}")
        end
      end
    end
  end
end
