require "yaml"
require "pathname"
require "fileutils"

module Metanorma
  module Cli
    class SiteGenerator
      def initialize(source, options = {})
        @source = find_realpath(source)
        @site_path = options.fetch(:output_dir, "site").to_s
        @manifest_file = find_realpath(options.fetch(:config, nil))
        @asset_folder = options.fetch(:asset_folder, "documents").to_s
        @collection_name = options.fetch(:collection_name, "documents.xml")

        ensure_site_asset_directory!
      end

      def self.generate(source, options = {})
        new(source, options).generate
      end

      def generate
        site_directory = asset_directory.join("..")

        Dir.chdir(site_directory) do
          select_source_files.each { |source| compile(source) }

          build_collection_file(collection_name)
          convert_to_html_page(collection_name, "index.html")
        end
      end

      private

      attr_reader :source, :asset_folder, :asset_directory
      attr_reader :site_path, :manifest_file, :collection_name

      def find_realpath(source_path)
        Pathname.new(source_path.to_s).realpath if source_path
      rescue Errno::ENOENT
        source_path
      end

      def select_source_files
        files = source_from_manifest

        if files.empty?
          files = Dir[File.join(source, "**", "*.adoc")]
        end

        files.flatten.uniq.reject { |file| File.directory?(file) }
      end

      def build_collection_file(collection_name)
        collection_path = [site_path, collection_name].join("/")
        UI.info("Building collection file: #{collection_path} ...")

        Relaton::Cli::RelatonFile.concatenate(
          asset_folder,
          collection_name,
          title: manifest[:collection_name],
          organization: manifest[:collection_organization],
        )
      end

      def compile(source)
        UI.info("Compiling #{source} ...")

        Metanorma::Cli::Compiler.compile(
          source.to_s, format: :asciidoc, "output-dir" => asset_folder
        )
      end

      def convert_to_html_page(collection, page_name)
        UI.info("Generating html site in #{site_path} ...")

        Relaton::Cli::XMLConvertor.to_html(collection)
        File.rename(Pathname.new(collection).sub_ext(".html").to_s, page_name)
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

      def manifest_config(manifest)
        {
          files: extract_config_data(
            manifest["metanorma"]["source"], "files"
          ) || [],

          collection_name: extract_config_data(
            manifest["relaton"]["collection"], "name"
          ),

          collection_organization: extract_config_data(
            manifest["relaton"]["collection"], "organization"
          ),
        }
      rescue NoMethodError
        raise Errors::InvalidManifestFileError.new("Invalid manifest file")
      end

      def extract_config_data(node, key)
        node ? node[key] : nil
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

        FileUtils.mkdir_p(@asset_directory) unless @asset_directory.exist?
      end
    end
  end
end
