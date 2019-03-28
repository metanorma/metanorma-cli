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
        }
      end

      def base_templates
        templates = [template_dir, "base"].join("/")
        build_template_hash(dir_files(templates), templates)
      end

      def type_specific_templates
        type_template_path.exist? || download_tempales
        type_template = [template_dir, type].join("/")
        build_template_hash(dir_files(type_template, doctype), type_template)
      end

      def build_template_hash(elements, source_root)
        Hash.new.tap do |hash|
          elements.each do |element|
            hash[element] = element.gsub("#{source_root}/", "")
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

        UI.say("Creating #{document_name}/#{destination}")
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
    end
  end
end
