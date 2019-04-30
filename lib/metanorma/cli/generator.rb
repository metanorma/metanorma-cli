require "uri"
require "pathname"
require "fileutils"
require "metanorma/cli/ui"

module Metanorma
  module Cli
    class Generator
      def initialize(name, type:, doctype:, **options)
        @name = name
        @type = type
        @doctype = doctype
        @options = options
        @template = options.fetch(:template, nil)
      end

      def run
        if Cli.writable_templates_path?
          if name && document_path.exist?
            return unless overwrite?(document_path)
            document_path.rmtree
          end

          create_metanorma_document
        end

      rescue Errno::EACCES
        permission_missing_error
      end

      # Generator.run
      #
      # This interface find / downloads the specified template
      # and then run the generator to create a new metanorma
      # document.
      #
      # By default it usages the default templates but user can
      # also provide a remote git teplate repo using --template
      # ooption, and in that case it will use that template.
      #
      def self.run(name, type:, doctype:, **options)
        new(name, options.merge(type: type, doctype: doctype)).run
      end

      private

      attr_reader :name, :type, :doctype, :options, :template

      def document_path
        @document_path ||= Pathname.pwd.join(name)
      end

      def create_metanorma_document
        type_template = type_specific_template

        unless type_template.empty?
          templates = base_templates.merge(type_template)
          templates.each { |source, dest| create_file(source, dest) }
        else
          UI.say(
            "Sorry, could not generate the document!\n" \
            "Template's are missing, please provide valid template URL"
          )
        end
      end

      def find_standard_template(type)
        Cli::GitTemplate.find_or_download_by(type)
      end

      def overwrite?(document_path)
        options[:overwrite] == true || ask_to_confirm(document_path) === "yes"
      end

      def base_templates
        base_template_root = Cli.base_templates_path
        build_template_hash(dir_files(base_template_root), base_template_root)
      end

      def type_specific_template
        type_template_path = custom_template || find_standard_template(type)
        doctype_templates  = dir_files(type_template_path, doctype)
        build_template_hash(doctype_templates, type_template_path, doctype)
      end

      def custom_template
        if template
          if template !~ URI::regexp
            return Pathname.new(template)
          end

          Cli::GitTemplate.download(type, repo: template)
        end
      end

      def build_template_hash(elements, source_root, type = nil)
        type_template_path = [source_root, type].join("/")

        Hash.new.tap do |hash|
          elements.each do |element|
            hash[element] = element.gsub(type_template_path, "")
          end
        end
      end

      def create_file(source, destination)
        target_path = [document_path, destination].join("/")
        target_path = Pathname.new(target_path)

        unless target_path.dirname.exist?
          FileUtils.mkdir_p(target_path.dirname)
        end

        file_creation_message(name, destination)
        FileUtils.copy_entry(source, target_path)
      end

      def dir_files(*arguments)
        paths = [*arguments, "**", "**"].join("/")
        files = Pathname.glob(paths, File::FNM_DOTMATCH) - [".", " .."]

        files.reject(&:directory?).map(&:to_s)
      end

      def ask_to_confirm(document)
        UI.ask(
          "You've an existing document with the #{document.to_s}\n" \
          "Still want to continue, and overwrite the existing one? (yes/no):",
        ).downcase
      end

      def file_creation_message(document, destination)
        UI.say("Creating #{[document, destination].join("/").gsub("//", "/")}")
      end

      def permission_missing_error
        UI.say(
          "Sorry, the current user doesn't have write permission\n" \
          "to #{Cli.templates_path}. Please change it to be writable or\n" \
          "run metanorma as different user with write permission to this path",
        )
      end
    end
  end
end
