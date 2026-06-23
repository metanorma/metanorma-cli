require "pathname"
require "fileutils"

module Metanorma
  module Cli
    class ConfigExporter
      FLAVOR_FILE_PATTERNS = [
        "metanorma/*/*.adoc",
        "isodoc/*/html/*",
        "isodoc/*/*.xsl",
        "isodoc/*/*.yml",
        "isodoc/*/*.yaml",
        "relaton/render/*.yml",
        "relaton/render/*.yaml",
      ].freeze

      def initialize(type)
        @type = type
      end

      def export
        validate_type? or return
        export_base_files
        export_taste_files
      end

      private

      attr_reader :type

      def validate_type?
        unless type
          UI.say("Please specify a standard type")
          return false
        end

        unless flavor_info
          UI.say("Couldn't load #{type}, please provide a valid type!")
          return false
        end

        true
      end

      # rubocop:disable Metrics/AbcSize
      def flavor_info
        @flavor_info ||= begin
          Metanorma::Cli.load_flavors
          dict = {}
          Metanorma::Registry.instance.processors.each do |type_sym, processor|
            dict[type_sym] = { format_keys: processor.output_formats.keys,
                               input: processor.input_format }
          end

          Metanorma::TasteRegister.instance.available_tastes.each do |taste|
            c = Metanorma::TasteRegister.instance.get_config(taste.to_sym)
            k1 = c.base_override.value_attributes.output_extensions&.split(",")
            base = c.base_flavor.to_sym
            dict[taste] = { format_keys: k1, base_flavor: base,
                            native_keys: dict[base][:format_keys],
                            input: dict[base][:input] }
          end

          dict[type.to_sym]
        end
      rescue StandardError
        nil
      end
      # rubocop:enable Metrics/AbcSize

      def base_flavor
        @base_flavor ||= flavor_info[:base_flavor] || type
      end

      def taste
        @taste ||= flavor_info[:base_flavor] ? type : nil
      end

      def output_dir
        @output_dir ||= "export-config-#{type}"
      end

      def export_base_files
        gem_lib_path = resolve_gem_lib_path(
          "metanorma-#{base_flavor}",
        ) or return
        FileUtils.mkdir_p(output_dir)
        copied = copy_matching_files(gem_lib_path, output_dir,
                                     FLAVOR_FILE_PATTERNS)
        report_result(copied, "metanorma-#{base_flavor}", output_dir)
      end

      def export_taste_files
        return unless taste

        gem_data_path = resolve_gem_data_path("metanorma-taste") or return
        source_path = gem_data_path.join(taste.to_s)
        unless source_path.exist?
          UI.say("Taste data directory not found: #{source_path}")
          return
        end

        dest_path = Pathname.new(output_dir).join("taste")
        copied = copy_tree(source_path, gem_data_path, dest_path)
        report_result(copied, "metanorma-taste/taste/#{taste}", dest_path)
      end

      def resolve_gem_lib_path(gem_name)
        gem_spec = Gem::Specification.find_by_name(gem_name)
        Pathname.new(gem_spec.full_gem_path).join("lib")
      rescue Gem::MissingSpecError
        UI.say("Gem #{gem_name} is not installed")
        nil
      end

      def resolve_gem_data_path(gem_name)
        gem_spec = Gem::Specification.find_by_name(gem_name)
        Pathname.new(gem_spec.full_gem_path).join("data")
      rescue Gem::MissingSpecError
        UI.say("Gem #{gem_name} is not installed")
        nil
      end

      def copy_matching_files(source_root, dest_dir, patterns)
        copied = []
        patterns.each do |pattern|
          Pathname.glob(source_root.join(pattern)).each do |source_file|
            copied << copy_file(source_file, source_root, dest_dir)
          end
        end
        copied.compact
      end

      def copy_tree(source_root, base_root, dest_dir)
        copied = []
        Pathname.glob(source_root.join("**", "*")).map do |source_file|
          copied << copy_file(source_file, base_root, dest_dir)
        end
        copied.compact
      end

      def copy_file(source_file, source_root, dest_dir)
        return if source_file.directory?

        relative_path = source_file.relative_path_from(source_root)
        dest_file = Pathname.new(dest_dir).join(relative_path)
        FileUtils.mkdir_p(dest_file.dirname) unless dest_file.dirname.exist?
        FileUtils.cp(source_file, dest_file)
        relative_path.to_s
      end

      def report_result(copied_files, source_name, dest_dir)
        if copied_files.empty?
          UI.say("No matching configuration files found in #{source_name}")
        else
          UI.say("Exported #{copied_files.size} configuration file(s) " \
                 "from #{source_name} to #{dest_dir}")
        end
      end
    end
  end
end
