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
      "metanorma-m3aawg",
      "metanorma-gb",
      "metanorma-generic",
      "metanorma-standoc",
      "metanorma-un",
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
      # OIML publications: the oiml taste's document-transformer hook
      # lazily requires this gem (OIML STS conversion); it is a
      # transformer provider, not a Processor flavor
      metanorma-oiml
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
      require_tastes
      (flavors + bundled_private_flavor_gems).each do |flavor_name|
        require(flavor_name)
      rescue LoadError, NameError => _e
        # NameError: released flavor gems predating the relaton-render 3
        # line raise at require time (e.g. metanorma-ogc 2.x subclassing
        # Relaton::Render::Parse); degrade them like absent flavors
        # instead of crashing every corpus run that bundles them.
        if SUPPORTED_GEMS.include?(flavor_name)
          gem_loading_error(flavor_name)
        else
          # Bundled-but-not-supported metanorma-* gems load best-effort:
          # the bundle pulls in data gems with no top-level entry file
          # (metanorma-ietf-data) and stale releases awaiting their
          # entry-file fix (metanorma-mko 1.1.1 predates the mko entry).
          # Their absence is not the user's error, so stay quiet.
          Metanorma::Cli::UI.debug("#{flavor_name} is not present!")
        end
      end
      load_bundled_plugins
    end

    private

    # Tastes register into Metanorma::Core::Flavors at require time; the
    # registry is the single extension point behind the CLI's taste
    # lookups (flavor dictionary, export-config, compile). Absence of the
    # gem degrades silently, like an absent flavor.
    def require_tastes
      require "metanorma-taste"
    rescue LoadError, NameError
      Metanorma::Cli::UI.debug("metanorma-taste is not present!")
    end

    # Bundled metanorma-plugin-* gems register their Asciidoctor
    # extensions at require time. Names come from the bundle. These
    # gems were never auto-loaded before, so one that is broken must not
    # take the CLI down or stop the remaining plugins from loading: a
    # plugin without a gem-name entry file, or whose require fails for
    # any reason, is skipped quietly.
    def load_bundled_plugins
      bundled_gem_names.grep(/\Ametanorma-plugin-/).each do |plugin_name|
        require(plugin_name)
      rescue StandardError, ScriptError => e
        Metanorma::Cli::UI.debug(
          "#{plugin_name} not loaded: #{e.class}: #{e.message[/[^\n]*/]}",
        )
      end
    end

    # Bundled metanorma-* gems outside the public flavor lists and the
    # non-flavor helpers: fully private flavors. Names are discovered
    # from the bundle, never listed here.
    def bundled_private_flavor_gems
      named = flavors + NON_FLAVOR_GEMS
      bundled_gem_names.select do |name|
        name.start_with?("metanorma-") &&
          !name.start_with?("metanorma-plugin-") &&
          !named.include?(name)
      end
    end

    def bundled_gem_names
      specs = begin
        Bundler.load.specs
      rescue StandardError
        Gem::Specification.find_all do |spec|
          spec.name.start_with?("metanorma-")
        end
      end
      specs.map(&:name).uniq
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
