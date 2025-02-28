require "pathname"
require "metanorma-utils"

# require "metanorma/cli/stringify_all_keys"

module Metanorma
  module Cli
    module Commands
      class Config < Thor
        Hash.include Metanorma::Utils::Hash
        Array.include Metanorma::Utils::Array

        class_option :global, aliases: "-g", type: :boolean, default: false,
                              desc: "Use global config"

        desc "get NAME", "Get config value"
        def get(name = nil)
          config, config_path = load_config(options[:global],
                                            create_default_config: false)

          if name.nil? && File.exist?(config_path)
            UI.say File.read(config_path, encoding: "utf-8")
          else
            UI.say(config.dig(*dig_path(name)) || "nil")
          end
        end

        desc "set NAME VALUE", "Set config value"
        def set(name, value = nil)
          config, config_path = load_config(options[:global])

          value = try_convert_to_bool(value)
          ypath = dig_path(name)
          deep_set(config, value, *ypath)

          save_config(config, config_path)
        end

        desc "unset [name]", "Set config [value] for [name]"
        def unset(name)
          config, config_path = load_config(options[:global])

          ypath = dig_path(name)
          deep_unset(config, *ypath)

          save_config(config, config_path)
        end

        def self.exit_on_failure?() true end

        # priority:
        # IDEAL: thor defaults -> global conf -> local conf -> env vars -> passed arguments
        # ACTUAL: all arguments -> global conf -> local conf
        # - thor doesn't provide to differentiate default values against passed args
        # - thor doesn't allow to get all args available for current command
        def self.load_configs(options, configs = [
          Metanorma::Cli.global_config_path, Metanorma::Cli.local_config_path
        ])
          result = options.dup
          configs.each do |config_path|
            next unless File.exist?(config_path)

            config_values = ::YAML::load_file(config_path).symbolize_all_keys[:cli] || {}
            result.merge!(config_values)
          end

          result
        end

        private

        def save_config(config, path)
          shash = config.stringify_all_keys
          File.write(path, shash.to_yaml, encoding: "utf-8")
        end

        def save_default_config(config_path)
          unless config_path.exist?
            unless config_path.dirname.exist?
              FileUtils.mkdir_p(config_path.dirname)
            end
            save_config({ cli: nil }, config_path)
          end
        end

        def load_config(global_config, create_default_config: true)
          config_path = Metanorma::Cli.config_path(global_config)

          unless File.exist?(config_path) || create_default_config
            config_path = Metanorma::Cli.config_path(true)
          end

          save_default_config(config_path)

          [::YAML::load_file(config_path).symbolize_all_keys || {},
           config_path]
        end

        def dig_path(str)
          str.split(".").map(&:to_sym)
        end

        def deep_set(hash, value, *keys)
          keys[0...-1].reduce(hash) do |acc, h|
            tmp = acc.public_send(:[], h)
            if tmp.nil?
              acc[h] = tmp = Hash.new
            end
            tmp
          end.public_send(:[]=, keys.last, value)
        end

        def deep_unset(hash, *keys)
          keys[0...-1].reduce(hash) do |acc, h|
            acc.public_send(:[], h)
          end.delete(keys.last)
        end

        def try_convert_to_bool(value)
          case value
          when "true"
            true
          when "false"
            false
          else
            value
          end
        end
      end
    end
  end
end
