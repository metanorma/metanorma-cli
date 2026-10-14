# frozen_string_literal: true

require "bundler"
require "metanorma/cli/ui"

module Metanorma
  class Flavor
    SUPPORTED_GEMS = [
      "metanorma-iso",
      "metanorma-iec",
      "metanorma-ieee",
      "metanorma-ietf",
      "metanorma-bipm",
      "metanorma-ribose",
      "metanorma-cc",
      "metanorma-iho",
      "metanorma-jis",
      # "metanorma-m3aawg",
      "metanorma-generic",
      "metanorma-standoc",
      # "metanorma-un",
      "metanorma-ogc",
      "metanorma-itu",
      "metanorma-plateau",
    ].freeze

    PRIVATE_SUPPORTED_GEMS = [
      "metanorma-ribose",
      # "metanorma-mpfa",
    ].freeze

    # Bundled metanorma-* gems that are not flavors; they are never
    # require'd by the loader. Everything bundled outside this list and
    # the flavor lists above loads generically, so fully private flavor
    # gems (nist, bsi, ...) work by mere presence in the consumer's
    # bundle — open CLI code never names them.
    NON_FLAVOR_GEMS = %w(
      metanorma
      metanorma-cli
      metanorma-core
      metanorma-standoc
      metanorma-document
      metanorma-utils
      metanorma-mirror
      metanorma-taste
      metanorma-release
      metanorma-acme
    ).freeze

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
      (flavors + bundled_private_flavor_gems).each do |flavor_name|
        require(flavor_name)
      rescue LoadError => _e
        gem_loading_error(flavor_name)
      rescue NameError => _e
        # Released flavor gems predating the relaton-render 3 line raise
        # NameError at require time (e.g. metanorma-ogc 2.x subclassing
        # Relaton::Render::Parse); degrade them like absent flavors
        # instead of crashing every corpus run that bundles them.
        gem_loading_error(flavor_name)
      end
    end

    private

    # Bundled metanorma-* gems outside the public flavor lists and the
    # non-flavor helpers: fully private flavors. Names are discovered
    # from the bundle, never listed here.
    def bundled_private_flavor_gems
      named = flavors + NON_FLAVOR_GEMS
      specs = begin
        Bundler.load.specs
      rescue StandardError
        Gem::Specification.find_all do |spec|
          spec.name.start_with?("metanorma-")
        end
      end
      specs.map(&:name).uniq.select do |name|
        name.start_with?("metanorma-") && !name.start_with?("metanorma-plugin-") &&
          !named.include?(name)
      end
    end

    private

    def flavors
      @flavors ||= begin
        result = [SUPPORTED_GEMS + PRIVATE_SUPPORTED_GEMS].flatten
        result.uniq!
        result
      end
    end

    def gem_loading_error(flavor_name)
      unless PRIVATE_SUPPORTED_GEMS.include?(flavor_name)
        Metanorma::Cli::UI.error(
          "[metanorma] Error: flavor gem #{flavor_name} is not present!",
        )
      end
    end
  end
end

# Activate flavors
Metanorma::Flavor.activate
