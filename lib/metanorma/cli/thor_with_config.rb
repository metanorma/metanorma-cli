require "thor"

require_relative "stringify_all_keys"

module Metanorma
  module Cli
    class ThorWithConfig < Thor
      no_commands do
        def options
          original_options = super.to_hash.symbolize_all_keys
          Thor::CoreExt::HashWithIndifferentAccess.new(
            Metanorma::Cli::Commands::Config.load_configs(original_options)
          )
        end

        def filter_compile_options(options)
          options.select do |k, _|
            %w[agree_to_terms no_install_fonts continue_without_fonts].include?(k)
          end.symbolize_all_keys
        end
      end
    end
  end
end
