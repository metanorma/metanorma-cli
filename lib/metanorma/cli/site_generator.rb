# frozen_string_literal: true

require "yaml"
require "pathname"
require "fileutils"

module Metanorma
  module Cli
    class SiteGenerator
      DEFAULT_RELATON_COLLECTION_INDEX = "documents.xml"
      DEFAULT_ASSET_FOLDER = "documents"
      DEFAULT_SITE_INDEX = "index.html"
      DEFAULT_CONFIG_FILE = "metanorma.yml"

      def initialize(source, options = {}, compile_options = {})
        @collection_queue = []
        @source = find_realpath(source)
        @site_path = options.fetch(
          :output_dir, Commands::Site::SITE_OUTPUT_DIRNAME
        ).to_s

        @asset_folder = options.fetch(:asset_folder, DEFAULT_ASSET_FOLDER).to_s
        @relaton_collection_index = options.fetch(:collection_name,
                                                  DEFAULT_RELATON_COLLECTION_INDEX)

        @manifest_file = find_realpath(options.fetch(:config, default_config))
        @template_dir = options.fetch(:template_dir, template_data("path"))
        @stylesheet = options.fetch(:stylesheet, template_data("stylesheet"))

        @compile_options = compile_options
      end

      def self.generate(source, options = {}, compile_options = {})
        new(source, options, compile_options).generate
      end

      def generate
        ensure_site_asset_directory!
        site_directory = asset_directory.join("..")

        fatals = select_source_files.map { |source| compile(source) }
          .flatten
          .compact

        raise Errors::FatalCompilationError, fatals unless fatals.empty?

        Dir.chdir(site_directory) do
          build_collection_file(relaton_collection_index)
          convert_to_html_page(relaton_collection_index, DEFAULT_SITE_INDEX)
        end

        dequeue_jobs
      end

      private

      attr_reader :source, :asset_folder, :asset_directory, :site_path,
                  :manifest_file, :relaton_collection_index, :stylesheet, :template_dir

      def find_realpath(source_path)
        Pathname.new(source_path.to_s).realpath if source_path
      rescue Errno::ENOENT
        source_path
      end

      def default_config
        default_file = Pathname.new(Dir.pwd).join(DEFAULT_CONFIG_FILE)
        default_file if File.exist?(default_file)
      end

      def select_source_files
        files = source_from_manifest

        if files.empty?
          files = Dir[File.join(source, "**", "*.adoc")]
        end

        files.flatten.uniq.reject { |file| File.directory?(file) }
      end

      def build_collection_file(relaton_collection_index_filename)
        collection_path = [site_path,
                           relaton_collection_index_filename].join("/")
        UI.info("Building collection file: #{collection_path} ...")

        Relaton::Cli::RelatonFile.concatenate(
          asset_folder,
          relaton_collection_index_filename,
          title: manifest[:collection_name],
          organization: manifest[:collection_organization],
        )
      end

      def compile(source)
        if collection_file?(source)
          return
        end

        UI.info("Compiling #{source} ...")

        options = @compile_options.merge(
          format: :asciidoc, output_dir: build_asset_output_directory(source),
          site_generate: true
        )

        options[:baseassetpath] = Pathname.new(source.to_s).dirname.to_s
        Metanorma::Cli::Compiler.compile(source.to_s, options)
      end

      def convert_to_html_page(relaton_index_filename, page_name)
        UI.info("Generating html site in #{site_path} ...")

        Relaton::Cli::XMLConvertor.to_html(
          relaton_index_filename,
          stylesheet,
          template_dir,
        )
        File.rename(
          Pathname.new(relaton_index_filename).sub_ext(".html").to_s,
          page_name,
        )
      end

      def template_data(node)
        template_node = manifest[:template]
        template_node&.fetch(node.to_s, nil)
      end

      def manifest
        @manifest ||= config_from_manifest || {
          files: [], collection_name: "", collection_organization: ""
        }
      end

      def config_from_manifest
        if manifest_file
          manifest_config(YAML.safe_load(File.read(manifest_file.to_s)))
        end
      end

      def manifest_config(manifest_from_yaml)
        {
          files: manifest_from_yaml.dig("metanorma", "source", "files") || [],
          template: manifest_from_yaml.dig("metanorma","template"),
          collection_name: manifest_from_yaml.dig("metanorma", "collection", "name"),
          collection_organization: manifest_from_yaml.dig("metanorma", "collection", "organization"),
        }



      rescue NoMethodError
        raise Errors::InvalidManifestFileError.new("Invalid manifest file")
      end

      def source_from_manifest
        @source_from_manifest ||= manifest[:files].map do |source_file|
          file_path = source.join(source_file).to_s
          file_path.include?("*") ? Dir.glob(file_path) : file_path
        end.flatten
      end

      def ensure_site_asset_directory!
        asset_path = [site_path, asset_folder].join("/")
        @asset_directory = Pathname.new(Dir.pwd).join(asset_path)

        create_directory_if_not_present!(@asset_directory)
      end

      def create_directory_if_not_present!(directory)
        FileUtils.mkdir_p(directory) unless directory.exist?
      end

      def build_asset_output_directory(source)
        sub_directory = Pathname.new(source.gsub(@source.to_s, "")).dirname.to_s
        sub_directory.gsub!("/sources", "")
        sub_directory.slice!(0)

        output_directory = asset_directory.join(sub_directory)
        create_directory_if_not_present!(output_directory)

        output_directory
      end

      def collection_file?(source)
        ext = File.extname(source)&.downcase

        if [".yml", ".yaml"].include?(ext)
          @collection_queue << source
        end
      end

      def dequeue_jobs
        job = @collection_queue.pop

        if job
          Cli::Collection.render(
            job,
            compile: @compile_options,
            output_dir: @asset_directory.join(".."),
          )
        end
      end
    end
  end
end
