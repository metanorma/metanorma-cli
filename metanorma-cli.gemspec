lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "metanorma/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-cli"
  spec.version       = Metanorma::Cli::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Metanorma is the standard of standards; the metanorma" \
                       " gem allows you to create any standard document type" \
                       " supported by Metanorma."
  spec.description   = "Executable to process any Metanorma standard."
  spec.homepage      = "https://www.metanorma.com"
  spec.license       = "BSD-2-Clause"

  spec.extra_rdoc_files = %w[README.adoc LICENSE CODE_OF_CONDUCT.md]
  spec.files         = Dir["{lib,bin,exe,docs}/**/*"] \
                     + Dir["templates/base/**/*"] \
                     + %w[Gemfile Rakefile i18n.yaml metanorma-cli.gemspec]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.1.0"

  spec.add_dependency "metanorma-ietf", "~> 3.6.0"
  spec.add_dependency "metanorma-iso", "~> 3.1.0"
  spec.add_dependency "mnconvert"
  # spec.add_dependency "thor", "~> 1.0" # inherited from vectory
  # spec.add_dependency "metanorma-gb", "~> 1.5.0"
  spec.add_dependency "metanorma-cc", "~> 2.7.0"
  spec.add_dependency "metanorma-iec", "~> 2.7.0"
  # spec.add_dependency 'metanorma-ribose', "~> 2.7.0"
  spec.add_dependency "metanorma-bipm", "~> 2.7.0"
  spec.add_dependency "metanorma-generic", "~> 3.1.0"
  spec.add_dependency "metanorma-standoc", "~> 3.1.0"
  # spec.add_dependency 'metanorma-mpfa', "~> 0.9.0"
  spec.add_dependency "git", "~> 1.5"
  spec.add_dependency "lutaml-model"
  spec.add_dependency "metanorma", "~> 2.2.0"
  spec.add_dependency "metanorma-iho", "~> 1.2.0"
  spec.add_dependency "metanorma-itu", "~> 2.7.0"
  # spec.add_dependency "metanorma-nist", "~> 2.7.0"
  spec.add_dependency "liquid", "~> 5"
  spec.add_dependency "metanorma-ieee", "~> 1.5.0"
  spec.add_dependency "metanorma-jis", "~> 0.6.0"
  spec.add_dependency "metanorma-ogc", "~> 2.8.0"
  spec.add_dependency "metanorma-plateau", "~> 1.1.0"
  spec.add_dependency "relaton-cli", ">= 0.8.2"

  spec.add_dependency "socksify"
  # spec.metadata["rubygems_mfa_required"] = "true"
  # NOBODY UNCOMMENTS THIS WITHOUT EXPLAINING TO ME HOW TO USE MFA
end
