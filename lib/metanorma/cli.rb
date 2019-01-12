require "metanorma/cli/version"
require "metanorma"

module Metanorma
  module Cli

    SUPPORTED_GEMS = [
      "metanorma-iso",
      "metanorma-ietf",
      "metanorma-gb",
      "metanorma-csd",
      "metanorma-csand",
      "metanorma-m3d",
      "metanorma-rsd",
      "metanorma-acme",
      "metanorma-standoc",
      "metanorma-unece",
      "metanorma-mpfd"
      "metanorma-nist"
      "metanorma-ogc"
    ]

    def self.load_flavors(flavor_names = SUPPORTED_GEMS)
      # puts "[metanorma] detecting flavors:"
      flavor_names.each do |flavor|
        begin
          # puts flavor
          require flavor
        rescue LoadError
          $stderr.puts "[metanorma] Error: flavor gem #{flavor} not present"
        end
      end
    end

    def self.load_all_flavors
      flavor_names = Gem::Specification.find_all do |g|
        g.name =~ /\Ametanorma-.*\Z/
      end.map(&:name)

      load_flavors(flavor_names)
    end

  end
end
