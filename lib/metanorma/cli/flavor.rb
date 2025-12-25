module Metanorma
  module Cli
    class Command < ThorWithConfig
      private

      def print_doctypes_table(type)
        ret = flavor_dictionary
        if type && ret[type.to_sym]
          new = {}
          new[type.to_sym] = ret[type.to_sym]
          ret = new
        end
        table_data = ret.map do |k, v|
          [k, v[:input], join_keys(v[:format_keys])]
        end
        UI.table(["Type", "Input", "Supported output format"], table_data)
      end

      def flavor_dictionary
        Metanorma::Cli.load_flavors
        ret = {}
        Metanorma::Registry.instance.processors.each do |type_sym, processor|
          ret[type_sym] = { format_keys: processor.output_formats.keys,
                            input: processor.input_format }
        end
        flavor_dictionary_taste(ret)
        ret
      end

      def flavor_dictionary_taste(ret)
        Metanorma::TasteRegister.instance.available_tastes.each do |taste|
          format_keys, base_flavor = taste_format_keys(taste)
          ret[taste] = { format_keys: format_keys, base_flavor: base_flavor,
                         native_keys: ret[base_flavor][:format_keys],
                         input: ret[base_flavor][:input] }
        end
        ret
      end

      def taste_format_keys(type)
        c = Metanorma::TasteRegister.instance.get_config(type.to_sym)
        k1 = c.base_override.value_attributes.output_extensions&.split(",")
        [k1, c.base_flavor.to_sym]
      end

      def single_type_extensions(type)
        dict, ret = single_type_extensions_prep(type)
        dict or return ret
        single_type_extensions_lookup(dict, type)
      end

      def single_type_extensions_lookup(dict, type)
        k = dict[type.to_sym][:format_keys]
        UI.say("Supported extensions: #{join_keys(k)}.")
        b = dict[type.to_sym][:base_flavor] and UI.say("Base flavor: #{b}")
        n = dict[type.to_sym][:native_keys] and
          UI.say("Flavor extensions: #{join_keys n}")
      end

      def single_type_extensions_prep(type)
        type or return [nil, false]
        ret = flavor_dictionary
        unless ret[type.to_sym]
          UI.say("Couldn't load #{type}, please provide a valid type!")
          return [nil, true]
        end
        [ret, true]
      end

      def all_type_extensions
        message = "Supported extensions per type: \n"
        ret = flavor_dictionary
        ret.each do |k, v|
          v[:base_flavor] and b = " (base flavor: #{v[:base_flavor]})"
          v[:native_keys] and
            n = ". (Flavor extensions: #{join_keys(v[:native_keys])})"
          message += "#{k}#{b}: #{join_keys(v[:format_keys])}#{n}.\n"
        end
        UI.say(message)
      end

      def backend_version(type)
        type and UI.say(find_backend(type).version)
      end

      def backend_processors
        @backend_processors ||= begin
          Metanorma::Cli.load_flavors
          Metanorma::Registry.instance.processors
        end
      end

      def find_backend(type)
        load_flavours(type)
        Metanorma::Registry.instance.find_processor(type&.to_sym)
      end

      def supported_backends
        UI.say("Metanorma #{Metanorma::VERSION}")
        UI.say("Metanorma::Cli #{VERSION}")
        Metanorma::Cli.load_flavors
        Metanorma::Registry.instance.processors.map do |_type, processor|
          UI.say(processor.version)
        end
      end

      DEPENDENCY_GEMS =
        %w(html2doc isodoc metanorma-utils mn2pdf mn-requirements isodoc-i18n
           metanorma-plugin-glossarist
           metanorma-plugin-lutaml relaton-cli pubid glossarist fontist
           plurimath lutaml expressir xmi lutaml-model emf2svg unitsml
           vectory ogc-gml oscal).freeze

      def dependencies_versions
        versions = Gem.loaded_specs
        DEPENDENCY_GEMS.sort.each do |k|
          UI.say("#{k} #{versions[k].version}")
        end
      end

      def join_keys(keys)
        [keys[0..-2].join(", "), keys.last].join(" and ")
      end

      def create_new_document(name, options)
        Metanorma::Cli::Generator.run(
          name,
          type: options[:type],
          doctype: options[:doctype],
          template: options[:template],
          overwrite: options[:overwrite],
        )
      end

      def load_flavours(type)
        Metanorma::Cli.load_flavors
        unless Metanorma::Registry.instance.find_processor(type&.to_sym)
          require "metanorma-#{type}"
        end
      end

      def select_wildcard_documents(filename)
        if filename.include?("*")
          Dir.glob(Pathname.new(filename))
        end
      end

      def compile_document(filename, options)
        Metanorma::Cli.load_flavors
        errors = Metanorma::Cli::Compiler.compile(filename, options)
        errors.each { |error| Util.log(error, :error) }
        exit(1) if errors.any?
      end

      EXPORT_CONFIG_FLAVOR_FILES = [
        "metanorma/*/*.adoc",
        "isodoc/*/html/*",
        "isodoc/*/*.yml",
        "relaton/render/*.yml",
      ].freeze

      def export_config_flavor(type)
        base, taste, dir = export_config_flavor_prep(type)
        base or return
        gem_lib_path = export_config_flavor_gem(base) or return
        copied_files = export_config_copy_files(gem_lib_path, dir)
        validate_copied_files_base(copied_files, base, dir)
        taste or return
        export_config_taste(taste, dir)
      end

      def export_config_copy_files(gem_lib_path, dir)
        copied_files = []
        EXPORT_CONFIG_FLAVOR_FILES.each do |pattern|
          full_pattern = gem_lib_path.join(pattern)
          Pathname.glob(full_pattern).each do |source_file|
            copied_files << export_config_copy_file(source_file, gem_lib_path,
                                                    dir)
          end
        end
        copied_files.compact
      end

      def export_config_copy_file(source_file, gem_lib_path, dir)
        source_file.directory? and return
        relative_path = source_file.relative_path_from(gem_lib_path)
        dest_file = Pathname.new(dir).join(relative_path)
        FileUtils.mkdir_p(dest_file.dirname) unless dest_file.dirname.exist?
        FileUtils.cp(source_file, dest_file)
        relative_path.to_s
      end

      def export_config_flavor_prep(type)
        unless type
          UI.say("Please specify a standard type")
          return [nil, nil, nil]
        end
        dict = flavor_dictionary
        unless dict[type.to_sym]
          UI.say("Couldn't load #{type}, please provide a valid type!")
          return [nil, nil, nil]
        end
        FileUtils.mkdir_p("export-config-#{type}")
        base = dict[type.to_sym][:base_flavor]
        [base || type, base ? type : nil, "export-config-#{type}"]
      end

      def export_config_flavor_gem(base)
        begin
          gem_spec = Gem::Specification.find_by_name("metanorma-#{base}")
        rescue Gem::MissingSpecError
          UI.say("Gem metanorma-#{base} is not installed")
          return
        end
        Pathname.new(gem_spec.full_gem_path).join("lib")
      end

      def validate_copied_files_base(copied_files, base, dir)
        if copied_files.empty?
          UI.say("No matching configuration files found in metanorma-#{base}")
        else
          UI.say("Exported #{copied_files.size} configuration file(s) " \
            "from metanorma-#{base} to #{dir}")
        end
      end

      def export_config_taste(taste, dir)
        gem_data_path = export_config_taste_gem or return
        source_path = gem_data_path.join(taste.to_s)
        unless source_path.exist?
          UI.say("Taste data directory not found: #{source_path}")
          return
        end
        dest_path = Pathname.new(dir).join("taste")
        copied_files = export_config_taste_copy_files(source_path,
                                                      gem_data_path, dest_path)
        validate_copied_files_taste(copied_files, taste, dest_path)
      end

      def export_config_taste_gem
        begin
          gem_spec = Gem::Specification.find_by_name("metanorma-taste")
        rescue Gem::MissingSpecError
          UI.say("Gem metanorma-taste is not installed")
          return
        end
        Pathname.new(gem_spec.full_gem_path).join("data")
      end

      def export_config_taste_copy_files(source_path, gem_data_path, dest_path)
        copied_files = []
        pattern = source_path.join("**", "*")
        Pathname.glob(pattern).each do |source_file|
          copied_files << export_config_copy_file(source_file, gem_data_path,
                                                  dest_path)
        end
        copied_files.compact
      end

      def validate_copied_files_taste(copied_files, taste, dest_path)
        if copied_files.empty?
          UI.say("No files found in metanorma-taste/taste/#{taste}")
        else
          UI.say("Exported #{copied_files.size} taste configuration file(s) " \
            "from metanorma-taste to #{dest_path}")
        end
      end
    end
  end
end
