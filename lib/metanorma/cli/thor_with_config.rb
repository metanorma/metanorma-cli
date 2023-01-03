require "thor"
require "metanorma-utils"

module Metanorma
  module Cli
    class ThorWithConfig < Thor
      Hash.include Metanorma::Utils::Hash
      Array.include Metanorma::Utils::Array

      no_commands do
        def options
          original_options = super.to_hash.symbolize_all_keys
          Thor::CoreExt::HashWithIndifferentAccess.new(
            Metanorma::Cli::Commands::Config.load_configs(original_options),
          )
        end

        def filter_compile_options(options)
          copts = %w[
            agree_to_terms
            no_install_fonts
            continue_without_fonts
            no_progress
            strict
          ]
          options.select { |k, _| copts.include?(k) }.symbolize_all_keys
        end
      end
    end
  end
end
