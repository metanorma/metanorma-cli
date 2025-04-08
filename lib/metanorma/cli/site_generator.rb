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

        # actually compile collection file(s)
        compile_collections!

        Dir.chdir(site_directory) do
          build_collection_file!(relaton_collection_index)
          convert_to_html_page!(relaton_collection_index, DEFAULT_SITE_INDEX)
        end
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

      # @dependency: files (YAML, XML, RXL) in asset_directory's parent, from
      # #compile_files! and #compile_collections!
      #
      # This looks for collection artifacts from the `collections`
      # sub-directory, and individual document artifacts from the `documents`
      # sub-directory.
      #
      # @output: documents.xml in site_path
      #
      # @param relaton_collection_index_filename [String] the name of the
      # collection index file (usually documents.xml), but can be changed
      # through the :collection_name option
      def build_collection_file!(relaton_collection_index_filename)
        collection_path = site_path.join(relaton_collection_index_filename)
        UI.info("Building collection file: #{collection_path} ...")

        # First concatenate individual document files
        # But be sure to provide a *relative* path of _site,
        # that is relative to the manifest file itself?  or relative to PWD!
        #
        # It has to be relative to PWD, otherwise the resolved relative paths
        # will simply not be valid.
        #
        # If paths are desired to be relative from the manifest file, then
        # `RelatonFile.concatenate` needs to accept a base path option, so
        # `concatenate` can calculate the correct full path to use.
        #
        target_path = asset_directory.parent.relative_path_from(Pathname.pwd)

        Relaton::Cli::RelatonFile.concatenate(
          target_path.to_s,
          relaton_collection_index_filename,
          title: manifest[:collection_name],
          organization: manifest[:collection_organization],
        )
      end

      # @dependency: file in file_path, from #select_source_files
      # @output: file in asset_folder
      def compile_file!(file_path)
        if collection_file?(file_path)
          @collection_queue << file_path
          return
        end

        UI.info("Compiling #{file_path} ...")

        # Incorporate output_filename_template so the output file
        # can be named as desired, using liquid template and Relaton LiquidDrop
        options = @compile_options.merge(
          output_filename_template: output_filename_template,
          format: :asciidoc,
          output_dir: ensure_site_asset_output_sub_directory!(file_path),
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

      # Use 'realpath' throughout to ensure consistency with file paths,
      # especially with temporary directories generated in RSpec.
      def ensure_site_asset_directory!
        asset_path = site_path.join(asset_folder)
        @asset_directory = Pathname.pwd.join(asset_path)
        @asset_directory.mkpath
        @asset_directory = @asset_directory.realpath
        @asset_directory
      end

      # TODO: spec
      def ensure_site_asset_output_sub_directory!(source)
        sub_directory = Pathname.new(
          source.to_s.gsub(@source_path.to_s, ""),
        ).dirname.to_s
        sub_directory.gsub!("/sources", "")
        sub_directory.slice!(0)

        outdir = asset_directory.join(sub_directory)
        outdir.mkpath

        outdir
      end

      # @param source [Pathname] the source file
      def collection_file?(source)
        [".yml", ".yaml"].include?(source.extname&.downcase)
      end

      # Compile each collection file encountered in the site manifest file.
      #
      # The collection files are compiled into the `collections` sub-directory
      # under the asset_directory.  The output folder specified in each of the
      # collections will be relative to this `collections` folder.
      #
      # Putting the files under the asset_directory is important because
      # the collection files are used to generate the collection index file
      # and the HTML page.  It is what `Relaton::Cli::RelatonFile.concatenate`
      # uses to find all artifacts and generate the correct links for them on
      # the site index.
      #
      # Potential conflicts considered:
      # On the one hand, each individual collection.yml specifies its own
      # output folder.  This has to be respected.
      #
      # On the other hand, the output folders specified in collection.yml files
      # naturally cannot be expected to live within the `asset_directory`.
      #
      # So, for the build_collection_file! method to correctly consider all
      # generated artifacts, we need to copy the collection files over to the
      # asset_directory.
      #
      # A question you may have: How much does the specific output folder
      # matter, when doing a site generate?  Since the intent is to generate a
      # site, the output folder is not really relevant.  The collection files
      # are copied over to the asset_directory anyway.
      #
      # TODO: parallelize the compilation of collection files?
      #
      def compile_collections!
        @collection_queue.compact.each do |file|
          Cli::Collection.render(
            file.to_s,
            compile: @compile_options,
            output_dir: asset_directory,
            site_generate: true,
          )
        end
      end
    end
  end
end
