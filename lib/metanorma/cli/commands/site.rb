# frozen_string_literal: true

require "pathname"
require "metanorma/cli/site_generator"
require "metanorma/cli/thor_with_config"

module Metanorma
  module Cli
    module Commands
      class Site < ThorWithConfig
        SITE_OUTPUT_DIRNAME = "_site"

        desc "generate [SOURCE_PATH]", "Generate site from collection"
        option :config,
               aliases: "-c",
               desc: "Metanorma configuration file"

        option :output_dir,
               aliases: "-o",
               default: Pathname.new(Dir.pwd).join(SITE_OUTPUT_DIRNAME).to_s,
               desc: "Output directory for generated site"

        option :output_filename_template,
               default: nil,
               desc: "Liquid template to generate output filenames" \
                     " (using Relaton model)"

        option :agree_to_terms,
               type: :boolean,
               desc: "Agree / Disagree with all third-party licensing" \
                     " terms presented (WARNING: do know what you are" \
                     " agreeing with!)"
        option :install_fonts,
               type: :boolean,
               default: true,
               desc: "Install required fonts"

        option :continue_without_fonts,
               type: :boolean,
               desc: "Continue processing even when fonts are missing"

        option :stylesheet,
               aliases: "-s",
               desc: "Stylesheet file path for rendering HTML page"

        option :template_dir,
               aliases: "-t",
               desc: "Liquid template directory to render site design"

        option :strict,
               aliases: "-S",
               type: :boolean,
               desc: "Strict compilation: abort if there are any errors"

        def generate(source_path = Dir.pwd)
          Cli::SiteGenerator.generate!(
            source_path,
            options,
            filter_compile_options(options),
          )
          UI.say("Site has been generated at #{options[:output_dir]}")
        rescue Cli::Errors::InvalidManifestFileError
          UI.error("Invalid data in: #{options[:config]}")
        end
      end
    end
  end
end
