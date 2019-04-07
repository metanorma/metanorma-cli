require "pathname"
require "fileutils"
require "metanorma/cli/ui"

module Metanorma
  module Cli
    class Generator
      def initialize(document_name, options)
        @document_name = document_name
        @type = options.fetch(:type, nil)
        @target = Pathname.pwd.join(document_name)
        @overwrite = options.fetch(:overwrite, false)
        @doctype = options.fetch(:doctype, "standard")
      end

      def run
        target.rmtree if target.exist? && deletable?

        templates = base_templates.merge(type_specific_templates)
        templates.each { |source, dest| create_file(source, dest) }
      end

      def self.run(document_name, options)
        new(document_name, options).run
      end

      private

      attr_reader :type, :doctype, :target, :document_name

      def deletable?
        @overwrite == true || ask_to_confirm === "yes"
      end

      def templates_sources
        @templates_sources ||= {
          csd: "https://github.com/metanorma/mn-templates-csd",
          ogc: "https://github.com/metanorma/mn-templates-ogc",
          iso: "https://github.com/metanorma/mn-templates-iso"
        }
      end

      def base_templates
        base_template_root = [template_dir, "base"].join("/")
        build_template_hash(dir_files(base_template_root), base_template_root)
      end

      def type_specific_templates
        type_template_path.exist? || download_tempales
        type_template_root = [template_dir, type].join("/")
        type_templates = dir_files(type_template_root, doctype)

        build_template_hash(type_templates, type_template_root, doctype)
      end

      def build_template_hash(elements, source_root, type = nil)
        type_template_path = [source_root, type].join("/")

        Hash.new.tap do |hash|
          elements.each do |element|
            hash[element] = element.gsub(type_template_path, "")
          end
        end
      end

      def download_tempales
        git = UI.run("which git")
        tempalte_source = templates_sources[type.to_sym]

        if !git.nil? && tempalte_source
          UI.say("Downloading #{type} tempaltes ...")
          UI.run("git clone #{tempalte_source} #{template_dir}/#{type}")
        end
      end

      def create_file(source, destination)
        target_path = [target, destination].join("/")
        target_path = Pathname.new(target_path)

        unless target_path.dirname.exist?
          FileUtils.mkdir_p(target_path.dirname)
        end

        file_creation_message(document_name, destination)
        FileUtils.copy_entry(source, target_path)
      end

      def dir_files(*arguments)
        paths = [*arguments, "**", "**"].join("/")
        Pathname.glob(paths).reject(&:directory?).map(&:to_s)
      end

      def template_dir
        @template_dir ||= [File.dirname(Cli.root), "templates"].join("/")
      end

      def type_template_path
        @type_template_path ||= Pathname.new([template_dir, type].join("/"))
      end

      def ask_to_confirm
        UI.ask(
          "You've an existing document with the same name\n" \
          "Still want to continue, and overwrite the existing one? (yes/no):",
        ).downcase
      end

      def file_creation_message(document, destination)
        UI.say("Creating #{[document, destination].join("/").gsub("//", "/")}")
      end
    end
  end
end
