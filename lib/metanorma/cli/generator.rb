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
        new(name, **options.merge(type: type, doctype: doctype)).run
      end

      private

      attr_reader :name, :type, :doctype, :options, :template

      def document_path
        @document_path ||= Pathname.pwd.join(name)
      end

      def create_metanorma_document
        type_template = type_specific_template

        if type_template.empty?
          UI.say(
            "Unable to generate document:\n#{create_metanorma_document_error}",
          )
        else
          templates = base_templates.merge(type_template)
          templates.each { |dest, source| create_file(source, dest) }
        end
      end

      def create_metanorma_document_error
        type == "ogc" && doctype == "charter" and return <<~ERR
          The template for OGC charter documents can be downloaded from https://github.com/opengeospatial/templates/tree/master/charter_templates
        ERR
        "Templates for type #{type} cannot be found -- "\
          "please provide a valid `type` or a template URL"
      end

      def find_standard_template(type)
        Cli::GitTemplate.find_or_download_by(type)
      end

      def overwrite?(document_path)
        options[:overwrite] == true || ask_to_confirm(document_path) === "yes"
      end

      def base_templates
        base_template_root = Cli.base_templates_path
        build_template_hash(base_template_root)
      end

      def type_specific_template
        template_path = custom_template || find_standard_template(type)
        return {} if template_path.nil?

        result = build_template_hash(template_path, doctype)
        return result if result.empty?

        result.merge(build_template_common_hash(template_path))
      end

      def custom_template
        if template
          if !template&.match?(URI::DEFAULT_PARSER.make_regexp)
            return Pathname.new(template)
          end

          Cli::GitTemplate.download(type, repo: template)
        end
      end

      def build_template_common_hash(source_root)
        common_path = Pathname.new(source_root) / "common"
        paths = dir_files(common_path)

        Hash.new.tap do |hash|
          paths.each do |path|
            dest = Pathname.new(path).relative_path_from(common_path).to_s
            hash[dest] = path
          end
        end
      end

      def build_template_hash(source_root, doctype = nil)
        source_path = Pathname.new(source_root)
        source_path /= doctype unless doctype.nil?
        paths = dir_files(source_path)
        Hash.new.tap do |hash|
          paths.each do |path|
            dest = Pathname.new(path).relative_path_from(source_path).to_s
            hash[dest] = path
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
          "You've an existing document with the #{document}\n" \
          "Still want to continue, and overwrite the existing one? (yes/no):",
        ).downcase
      end

      def file_creation_message(document, destination)
        UI.say("Creating #{[document, destination].join('/').gsub('//', '/')}")
      end

      def permission_missing_error
        UI.say(
          "Unable to generate document:\n" \
          "The current user does not have permission to write to this path:\n" \
          "#{Cli.templates_path}\n" \
          "Please ensure the path is writable by the current user, or\n" \
          "run Metanorma using a different user with write permissions.",
        )
      end
    end
  end
end
