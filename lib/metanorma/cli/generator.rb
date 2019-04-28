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
      end

      def run
        if name && document_path.exist?
          return unless overwrite?(document_path)
          document_path.rmtree
        end

        unless Cli.templates_path_access
          UI.say(
            "Sorry, the current user is unable to write to the #{Cli.templates_path} directory.\n\n" \
            "Please check permission for #{Cli.templates_path}, or try run metanorma with another user"
          )
          return
        end

        create_metanorma_document
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

      attr_reader :name, :type, :doctype, :options

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

      def find_template(type)
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
        type_template_path = custom_template || find_template(type)
        doctype_templates  = dir_files(type_template_path, doctype)
        build_template_hash(doctype_templates, type_template_path, doctype)
      end

      def custom_template
        if options[:template]
          Cli::GitTemplate.download(type, repo: options[:template])
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
    end
  end
end
