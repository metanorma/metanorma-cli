module Metanorma
  module Cli
    module FlavorMethods
      DEPENDENCY_GEMS =
        %w(html2doc isodoc metanorma-utils mn2pdf mn-requirements isodoc-i18n
           metanorma-core metanorma-plugin-glossarist metanorma-plugin-lutaml
           metanorma-taste relaton-cli pubid glossarist fontist
           plurimath lutaml expressir xmi lutaml-model emf2svg unitsml
           vectory ogc-gml oscal suma).freeze

      private

      def print_doctypes_table(type)
        ret = flavor_dictionary
        if type && ret[type.to_sym]
          filtered = {}
          filtered[type.to_sym] = ret[type.to_sym]
          ret = filtered
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
          b = " (base flavor: #{v[:base_flavor]})" if v[:base_flavor]
          n = if v[:native_keys]
                ". (Flavor extensions: " \
                  "#{join_keys(v[:native_keys])})"
              end
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
        type and Metanorma::Core::FlavorLoader.load_flavor(type)
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
        abort if errors.any?
      end
    end
  end
end
