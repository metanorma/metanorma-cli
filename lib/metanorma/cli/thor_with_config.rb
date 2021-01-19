require "thor"

module Metanorma
  module Cli
    class ThorWithConfig < Thor
      no_commands {
        def options
          @options_cache if @options_cache

          original_options = super
          result = Metanorma::Cli::Commands::Config.load_configs(original_options.to_hash)

          @options_cache = Thor::CoreExt::HashWithIndifferentAccess.new(result)
        end
      }
    end
  end
end