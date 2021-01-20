require "pathname"

module Metanorma
  module Cli
    module Commands
      class Config < Thor
        class_option :global, aliases: "-g", type: :boolean, default: false, desc: "Use global config"

        desc "get NAME", "Get config value"
        def get(name = nil)
          config_path = Metanorma::Cli.config_path(options.global)
          write_default_config(config_path) unless File.exists?(config_path)

          if name.nil?
            print File.read(config_path, encoding: "utf-8")
          else
            config = ::YAML::load_file(config_path) || {}
            ypath = name.split(".").map(&:to_sym)

            print(config.dig(*ypath) || "nil")
          end
        end

        desc "set NAME VALUE", "Set config value"
        def set(name, value = nil)
          config_path = Metanorma::Cli.config_path(options.global)
          write_default_config(config_path) unless File.exists?(config_path)

          config = ::YAML::load_file(config_path) || {}

          value = case value
                  when "true"
                    true
                  when "false"
                    false
                  else
                    value
                  end

          ypath = name.split(".").map(&:to_sym)
          deep_set(config, value, *ypath)

          p config

          File.write(config_path, config.to_yaml, encoding: "utf-8")
        end

        desc "unset [name]", "Set config [value] for [name]"
        def unset(name)
          config_path = Metanorma::Cli.config_path(options.global)
          write_default_config(config_path) unless File.exists?(config_path)

          config = ::YAML::load_file(config_path) || {}

          ypath = name.split(".").map(&:to_sym)
          deep_unset(config, *ypath)

          File.write(config_path, config.to_yaml, encoding: "utf-8")
        end

        def self.exit_on_failure?() true end

        # priority:
        # IDEAL: thor defaults -> global conf -> local conf -> env vars -> passed arguments
        # ACTUAL: all arguments -> global conf -> local conf
        # - thor doesn't provide to differentiate default values against passed args
        # - thor doesn't allow to get all args available for current command
        def self.load_configs(options, configs = [Metanorma::Cli.global_config_path, Metanorma::Cli.local_config_path])
          result = options.dup
          configs.each do |config_path|
            next unless File.exists?(config_path)
            config_values = ::YAML::load_file(config_path)[:cli] || {}
            result.merge!(config_values) if config_values
          end

          # TODO override with env vars

          result
        end

        private

        def write_default_config(config_path)
          unless config_path.exist?
            unless config_path.dirname.exist?
              FileUtils.mkdir_p(config_path.dirname)
            end
            File.write(config_path, { :cli => nil }.to_yaml, encoding: "utf-8")
          end
        end

        def deep_set(hash, value, *keys)
          keys[0...-1].inject(hash) do |acc, h|
            tmp = acc.public_send(:[], h)
            if tmp.nil?
              acc[h] = tmp = Hash.new
            end
            tmp
          end.public_send(:[]=, keys.last, value)
        end

        def deep_unset(hash, *keys)
          keys[0...-1].inject(hash) do |acc, h|
            acc.public_send(:[], h)
          end.delete(keys.last)
        end
      end
    end
  end
end
