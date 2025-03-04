# frozen_string_literal: true

require "lutaml/model"

module Metanorma
  class SiteManifest < Lutaml::Model::Serializable
    class SourceEntries < Lutaml::Model::Serializable
      attribute :files, :string, collection: true
    end

    class SiteMetadata < Lutaml::Model::Serializable
      attribute :organization, :string
      attribute :name, :string
    end

    class SiteTemplate < Lutaml::Model::Serializable
      attribute :path, :string
      attribute :stylesheet, :string
      attribute :output_filename_template, :string
    end

    class Manifest < Lutaml::Model::Serializable
      attribute :source, SourceEntries
      attribute :collection, SiteMetadata
      attribute :template, SiteTemplate
    end
    attribute :metanorma, Manifest
  end
end
