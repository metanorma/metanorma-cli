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

      # rubocop:disable Metrics/AbcSize
      def initialize(source_path, options = {}, compile_options = {})
        @collection_queue = []
        @source_path = find_realpath(source_path)
        @site_path = Pathname.new(options.fetch(
                                    :output_dir, Commands::Site::SITE_OUTPUT_DIRNAME
                                  ))

        @asset_folder = options.fetch(:asset_folder, DEFAULT_ASSET_FOLDER).to_s
        @relaton_collection_index = options.fetch(
          :collection_name,
          DEFAULT_RELATON_COLLECTION_INDEX,
        )

        @manifest_file = find_realpath(options.fetch(:config, default_config))
        @template_dir = options.fetch(:template_dir, template_data("path"))
        @stylesheet = options.fetch(:stylesheet, template_data("stylesheet"))
        @output_filename_template = options.fetch(
          :output_filename_template,
          template_data("output_filename"),
        )

        # Determine base path for template files
        # If template_dir is not absolute, then it is relative to the manifest
        # file.
        # If manifest file is not provided, then it is relative to the current
        # directory.
        @base_path = if manifest_file.nil?
                       Pathname.pwd
                     else
                       Pathname.new(manifest_file).parent
                     end

        @compile_options = compile_options
      end
      # rubocop:enable Metrics/AbcSize

      def self.generate!(source, options = {}, compile_options = {})
        new(source, options, compile_options).generate!
      end

      def generate!
        ensure_site_asset_directory!

        # compile individual document files
        compile_files!(select_source_files)

        site_directory = asset_directory.parent

        Dir.chdir(site_directory) do
          build_collection_file!(relaton_collection_index)
          convert_to_html_page!(relaton_collection_index, DEFAULT_SITE_INDEX)
        end

        # actually compile collection file(s)
        compile_collections!
      end

      private

      attr_reader :source_path, :asset_folder, :asset_directory, :site_path,
                  :manifest_file, :relaton_collection_index, :stylesheet,
                  :template_dir,
                  :output_filename_template,
                  :base_path

      def find_realpath(path)
        Pathname.new(path).realpath if path
      rescue Errno::ENOENT
        path
      end

      def default_config
        default_file = Pathname.pwd.join(DEFAULT_CONFIG_FILE)
        default_file if File.exist?(default_file)
      end

      # @return [Array<Pathname>] the list of ADOC source files
      def select_source_adoc_files
        select_source_files do |source_path|
          source_path.glob("**/*.adoc")
        end
      end

      # @return [Array<Pathname>] the list of YAML source files
      def select_source_collection_files
        select_source_files do |source_path|
          source_path.glob("**/*.{yaml,yml}")
        end.select do |f|
          collection_file?(f)
        end
      end

      # Select source files from the manifest if available, otherwise
      # select all .adoc files in the source directory.
      # If a block is given, yield the source directory to the block.
      #
      # @return [Array<Pathname>] the list of source files
      # @yieldparam source [Pathname] the source directory
      # @yieldreturn [Array<Pathname>] the list of source files
      # @example
      #  select_source_files do |source|
      #    source.glob("**/*.adoc")
      #  end
      #  # => [#<Pathname:source/1.adoc>, #<Pathname:source/2.adoc>]
      #
      def select_source_files
        files = source_from_manifest

        if files.empty?
          files = if block_given?
                    yield(source_path)
                  else
                    source_path.glob("**/*.adoc")
                  end
        end

        result = files.flatten
        result.uniq!
        result.reject!(&:directory?)
        result
      end

      # @dependency: files in asset_folder, from #compile_files! and #compile_collections!
      # @output: documents.xml in site_path
      def build_collection_file!(relaton_collection_index_filename)
        collection_path = site_path.join(relaton_collection_index_filename)
        UI.info("Building collection file: #{collection_path} ...")

        Relaton::Cli::RelatonFile.concatenate(
          asset_folder,
          relaton_collection_index_filename,
          title: manifest[:collection_name],
          organization: manifest[:collection_organization],
        )
      end

      # @dependency: file in file_path, from #select_source_files
      # @output: file in asset_folder
      def compile_file!(file_path)
        if collection_file?(file_path)
          return
        end

        UI.info("Compiling #{file_path} ...")

        # Incorporate output_filename_template so the output file
        # can be named as desired, using liquid template and Relaton LiquidDrop
        options = @compile_options.merge(
          output_filename_template: output_filename_template,
          format: :asciidoc,
          output_dir: build_asset_output_directory!(file_path),
          site_generate: true,
        )

        options[:baseassetpath] = Pathname.new(file_path.to_s).dirname.to_s
        Metanorma::Cli::Compiler.compile(file_path.to_s, options)
      end

      # @dependency: files in source_path, from #select_source_files
      # @output: files in asset_folder
      def compile_files!(files)
        fatals = files.map { |file| compile_file!(file) }
        fatals.flatten!
        fatals.compact!

        raise Errors::FatalCompilationError, fatals unless fatals.empty?
      end

      # Given a path, return the full path if it is not nil.
      # If the path is absolute, return the path as is.
      # If the path is relative, return the path relative to the base path.
      # @param some_path [String, nil] the path to be converted to full path
      # @return [String, nil] the full path
      def full_path_for(some_path)
        if some_path.nil?
          nil
        elsif Pathname.new(some_path).absolute?
          some_path
        elsif !base_path.nil?
          base_path.join(some_path)
        end
      end

      # @dependency: documents.xml from #build_collection_file!
      # @output: index.html in site_path
      def convert_to_html_page!(relaton_index_filename, page_name)
        UI.info("Generating html site in #{site_path} ...")

        Relaton::Cli::XMLConvertor.to_html(
          relaton_index_filename,
          full_path_for(stylesheet),
          full_path_for(template_dir),
        )

        File.rename(
          Pathname.new(relaton_index_filename).sub_ext(".html").to_s,
          page_name,
        )
      end

      def template_data(node)
        manifest[:template]&.public_send(node.to_s)
      end

      def manifest
        @manifest ||= config_from_manifest || {
          files: [],
          collection_name: "",
          collection_organization: "",
        }
      end

      def config_from_manifest
        if manifest_file
          manifest_config(
            Metanorma::SiteManifest::Base.from_yaml(
              File.read(manifest_file.to_s),
            ),
          )
        end
      end

      def manifest_config(manifest_model)
        {
          files: manifest_model&.metanorma&.source&.files || [],
          template: manifest_model&.metanorma&.template,
          collection_name: manifest_model
            .metanorma
            .collection
            .name,
          collection_organization: manifest_model
            .metanorma
            .collection
            .organization,
        }
      rescue NoMethodError
        raise Errors::InvalidManifestFileError.new("Invalid manifest file")
      end

      def source_from_manifest
        @source_from_manifest ||= begin
          result = manifest[:files].map do |source_file|
            file_path = source_path.join(source_file)
            file_path.to_s.include?("*") ? source_path.glob(source_file) : file_path
          end
          result.flatten!
          result
        end
      end

      def ensure_site_asset_directory!
        asset_path = [site_path, asset_folder].join("/")
        @asset_directory = Pathname.new(Dir.pwd).join(asset_path)

        create_directory_if_not_present!(@asset_directory)
      end

      def create_directory_if_not_present!(directory)
        FileUtils.mkdir_p(directory) unless directory.exist?
      end

      def build_asset_output_directory!(source)
        sub_directory = Pathname.new(source.to_s.gsub(@source_path.to_s,
                                                      "")).dirname.to_s
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

      # Only one collection file is supported for now??
      #
      # TODO: parallelize the compilation of collection files?
      def compile_collections!
        @collection_queue.compact.each do |file|
          Cli::Collection.render(
            file.to_s,
            compile: @compile_options,
            output_dir: asset_directory.parent,
            site_generate: true,
          )
        end
      end
    end
  end
end
