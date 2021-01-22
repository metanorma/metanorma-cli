require "thor"

module Metanorma
  module Cli
    class ThorWithConfig < Thor
      no_commands do
        def options
          @options_cache

          original_options = super
          result = Metanorma::Cli::Commands::Config.load_configs(original_options.to_hash)

          @options_cache = Thor::CoreExt::HashWithIndifferentAccess.new(result)
        end

        def filter_compile_options(options)
          options.select do |k, _|
            ["agree-to-terms", "no-install-fonts", "continue-without-fonts"].include?(k)
          end.map { |k, v| [k.to_sym, v] }.to_h
        end
      end
    end
  end
end
