require "yaml"

module Metanorma
  module Cli
    class TemplateRepo
      def initialize(options = {})
        @name = options.fetch(:name)
        @source = options.fetch(:source)
        @type = options.fetch(:type, "custom")
        @overwrite = options.fetch(:overwrite, false)
      end

      def add
        create_template_config
        add_new_template(name, source, type)
        write_to_template_config(templates)

        templates[:templates]
      end

      def self.add(name, source, options = {})
        new(options.merge(name: name, source: source)).add
      end

      private

      attr_reader :name, :source, :type, :overwrite

      def templates
        @templates ||= YAML.load(template_config_file.read)
      end

      def template_config_file
        @template_config_file ||= Cli.config_path
      end

      def create_template_config
        unless template_config_file.exist?
          unless template_config_file.dirname.exist?
            FileUtils.mkdir_p(template_config_file.dirname)
          end

          write_to_template_config({templates: []})
        end
      end

      def write_to_template_config(templates)
        File.write(template_config_file, templates.to_yaml)
      end

      def add_new_template(name, source, type)
        names = templates[:templates].map { |template| template[:name].to_s }

        if names.include?(name.to_s) && overwrite == false
          raise Errors::DuplicateTemplateError.new("Duplicate metanorma template")
        end

        templates[:templates].push({ name: name, source: source, type: type })
      end
    end
  end
end
