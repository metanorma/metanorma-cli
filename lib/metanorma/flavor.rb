# frozen_string_literal: true

require "metanorma/cli/ui"

module Metanorma
  class Flavor
    SUPPORTED_GEMS = [
      "metanorma-iso",
      "metanorma-iec",
      "metanorma-ieee",
      "metanorma-ietf",
      "metanorma-bipm",
      "metanorma-cc",
      "metanorma-csa",
      "metanorma-iho",
      "metanorma-jis",
      # "metanorma-m3aawg", 
      "metanorma-generic",
      "metanorma-standoc",
      "metanorma-un",
      "metanorma-ogc",
      "metanorma-itu",
    ].freeze

    PRIVATE_SUPPORTED_GEMS = [
      "metanorma-ribose",
      # "metanorma-mpfa",
      "metanorma-nist",
    ].freeze

    def self.activate
      new.activate
    end

    def self.load_flavors
      new.load_flavors
    end

    def activate
      flavors.each do |flavor_name|
        gem(flavor_name)
      rescue LoadError, MissingSpecError => _e
        Metanorma::Cli::UI.debug("#{flavor_name} is not present!")
      end
    end

    def load_flavors
      flavors.each do |flavor_name|
        require(flavor_name)
      rescue LoadError => _e
        gem_loading_error(flavor_name)
      end
    end

    private

    def flavors
      @flavors ||= [SUPPORTED_GEMS + PRIVATE_SUPPORTED_GEMS].flatten.uniq
    end

    def gem_loading_error(flavor_name)
      unless PRIVATE_SUPPORTED_GEMS.include?(flavor_name)
        Metanorma::Cli::UI.error(
          "[metanorma] Error: flavor gem #{flavor_name} not present",
        )
      end
    end
  end
end

# Activate flavors
Metanorma::Flavor.activate
