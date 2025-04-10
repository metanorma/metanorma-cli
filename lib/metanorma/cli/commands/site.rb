# frozen_string_literal: true

require "pathname"
require "metanorma/cli/site_generator"
require "metanorma/cli/thor_with_config"

module Metanorma
  module Cli
    module Commands
      class Site < ThorWithConfig
        SITE_OUTPUT_DIRNAME = "_site"

        desc "generate [SITE_MANIFEST_PATH]", "Generate site from collection"
        option :config,
               aliases: "-c",
               desc: "Metanorma configuration file " \
                     "(deprecated: use the first argument of " \
                     "the command instead)"

        option :output_dir,
               aliases: "-o",
               default: Pathname.pwd.join(SITE_OUTPUT_DIRNAME).to_s,
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
               desc: "Stylesheet file path " \
                     "(relative to the current working directory) " \
                     "for rendering HTML page"

        option :template_dir,
               aliases: "-t",
               desc: "Liquid template directory " \
                     "(relative to the current working directory) " \
                     "to render site design"

        option :strict,
               aliases: "-S",
               type: :boolean,
               desc: "Strict compilation: abort if there are any errors"

        # If no argument is provided, work out the base
        # path to use for calculation of full paths for
        # files referenced in the site manifest.
        #
        # Additionally, if the config file is not provided,
        # use the current working directory as the base path.
        # If the config file is provided, use the directory
        # of the config file as the base path.
        #
        # If the source path is a file and no config file is provided,
        # treat the source path as the config file.
        # Similar to the above, use the directory of the config file
        # as the base path.
        #
        # For stylesheet and template_dir options, and if they are
        # relative paths, they will be resolved relative to whatever
        # defined them.
        #
        # So, if they are provided via the command line,
        # resolve them relative to the current working directory.
        # If they are provided via the site manifest,
        # resolve them relative to the site manifest's directory.
        def generate(manifest_path = nil)
          my_options = options.dup # because options is not modifiable

          base_path = calculate_base_path!(my_options, manifest_path).realpath

          calculate_full_paths!(my_options)

          Cli::SiteGenerator.generate!(
            base_path,
            my_options,
            filter_compile_options(my_options),
          )
          UI.say("Site has been generated at #{options[:output_dir]}")
        rescue Cli::Errors::InvalidManifestFileError
          UI.error("Invalid data in: #{options[:config]}")
        end

        private

        # Make relative paths absolute.
        def calculate_full_paths!(my_options)
          %i[stylesheet template_dir].each do |key|
            if my_options[key]
              path = Pathname.new(my_options[key])
              if path.relative?
                my_options[key] = Pathname.pwd.join(path)
              end
            end
          end
        end

        # Calculate the base path for the site generation.
        def calculate_base_path!(my_options, manifest_path = nil)
          config_file = options[:config]
          if manifest_path.nil?
            if config_file.nil?
              # If no config file is given, use the current working directory
              # as the base path.
              Pathname.pwd
            else
              # If a config file is given, use it as the config file
              # and use its directory as the base path.
              Pathname.new(config_file).dirname
            end
          elsif File.file?(manifest_path) && config_file.nil?
            # If a file is given, use it as the config file
            # and use its directory as the base path.
            my_options["config"] = manifest_path
            Pathname.new(manifest_path).dirname
          else
            # If directory is given, use it as the base path.
            Pathname.new(manifest_path)
          end
        end
      end
    end
  end
end
