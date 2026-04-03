# frozen_string_literal: true

require "lutaml/model"

module Metanorma
  module Config
    class Template < Lutaml::Model::Serializable
      attribute :name, :string
      attribute :source, :string
      attribute :type, :string
    end

    class Cli < Lutaml::Model::Serializable
      attribute :agree_to_terms, :boolean
      attribute :install_fonts, :boolean
      attribute :continue_without_fonts, :boolean
      attribute :progress, :boolean
      attribute :strict, :boolean
    end

    class Base < Lutaml::Model::Serializable
      attribute :templates, Template, collection: true
      attribute :cli, Cli

      key_value do
        map to: :cli
      end
    end
  end
end
