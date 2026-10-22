# frozen_string_literal: true

require "suma"

module Metanorma
  module Cli
    # Reports whether a Metanorma site manifest is schema-bearing: any
    # collection manifest it references carries EXPRESS schemas, either as
    # `schemas-only` entries or as a `schemas.yaml` beside a `collection.yml`.
    # Schema-bearing sites build through the suma pipeline, which compiles
    # those schemas into the documents the manifests attach.
    class SchemaSiteDetector
      COLLECTION_FILENAME = "collection.yml"
      SCHEMAS_FILENAME = "schemas.yaml"

      def initialize(metanorma_yaml_path)
        @path = metanorma_yaml_path
      end

      def schema_bearing?
        source_files.any? { |file| schema_collection?(file) }
      end

      private

      def source_files
        site = Metanorma::SiteManifest::Base.from_yaml(File.read(@path))
        Array(site.metanorma&.source&.files)
      end

      def schema_collection?(file)
        return false unless /\.ya?ml\z/.match?(file)

        path = File.expand_path(file, File.dirname(@path))
        return false unless File.exist?(path)

        return true if schemas_beside?(path)

        walk(Suma::CollectionConfig.from_file(path).manifest,
             File.dirname(path))
      end

      # Entries resolve their `file` relative to the manifest that declares
      # them, so the walk carries the declaring directory along.
      def walk(manifest, dir)
        return false unless manifest
        return true if manifest.schemas_only

        child_dir = dir
        if manifest.file
          path = File.expand_path(manifest.file, dir)
          return true if schemas_beside?(path)

          child_dir = File.dirname(path)
        end

        Array(manifest.entry).any? { |entry| walk(entry, child_dir) }
      end

      def schemas_beside?(manifest_path)
        File.basename(manifest_path) == COLLECTION_FILENAME &&
          File.exist?(File.join(File.dirname(manifest_path), SCHEMAS_FILENAME))
      end
    end
  end
end
