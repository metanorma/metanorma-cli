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
  spec.required_ruby_version = Gem::Requirement.new(">= 3.3.0")

  # The newest STABLE of these seven still subclasses the removed Relaton::Render::Parse
  # at require time (relaton-render#148); the prerelease floors pair every
  # resolution with the shim-free generation.
  spec.add_dependency "metanorma-ietf", ">= 3.7.12.pre.alpha.1"
  spec.add_dependency "metanorma-iso", ">= 3.5.1.pre.alpha.1"
  # The taste-chain-aware FlavorLoader (0.2.4 resolves tastes to
  # nonexistent metanorma-<taste> gems) - the floor names the line.
  spec.add_dependency "metanorma-core", ">= 0.2.5.pre.alpha.1"
  spec.add_dependency "mnconvert", "~> 1.89"
  spec.add_dependency "metanorma-release", "~> 0.2"
  # spec.add_dependency "thor", "~> 1.0" # inherited from vectory
  # revived flavors: floor the candidates that carry the coordinated fixes
  spec.add_dependency "metanorma-gb", ">= 1.5.9.pre.alpha.3"
  spec.add_dependency "metanorma-un", ">= 0.12.20.pre.alpha.2"
  spec.add_dependency "metanorma-m3aawg", ">= 2.2.6.pre.alpha.2"
  spec.add_dependency "metanorma-bipm", ">= 2.9.1.pre.alpha.1"
  spec.add_dependency "metanorma-cc", ">= 2.9.1.pre.alpha.1"
  spec.add_dependency "metanorma-generic", ">= 3.5.1.pre.alpha.1"
  spec.add_dependency "metanorma-iec", ">= 2.9.1.pre.alpha.1"
  spec.add_dependency "metanorma-ribose", ">= 2.9.1.pre.alpha.1"
  spec.add_dependency "metanorma-standoc", ">= 3.5.1.pre.alpha.1"
  spec.add_dependency "metanorma-taste", "~> 1.1"
  # spec.add_dependency 'metanorma-mpfa', "~> 0.9.0"
  spec.add_dependency "git", ">= 3.0"
  spec.add_dependency "lutaml-model", "~> 0.8"
  spec.add_dependency "metanorma", ">= 2.5.6.pre.alpha.2"
  spec.add_dependency "metanorma-iho", ">= 1.4.1.pre.alpha.1"
  spec.add_dependency "metanorma-itu", ">= 2.9.3.pre.alpha.1"
  spec.add_dependency "liquid", "~> 5"
  spec.add_dependency "metanorma-ieee", ">= 1.7.1.pre.alpha.1"
  spec.add_dependency "metanorma-jis", ">= 1.2.1.pre.alpha.1"
  spec.add_dependency "metanorma-ogc", ">= 2.10.1.pre.alpha.1"
  spec.add_dependency "metanorma-plateau", ">= 1.3.2.pre.alpha.1"
  # OIML publications (B/D/G/R/V series): the oiml taste's
  # document-transformer hook lazily requires this gem
  spec.add_dependency "metanorma-oiml", ">= 0.1.0"
  spec.add_dependency "canon", ">= 0.2.12"
  spec.add_dependency "relaton-cli", ">= 3.0.0"
  # the coordinated isodoc candidate carries the bibrender nil-guard (isodoc#852)
  spec.add_dependency "isodoc", ">= 3.7.4.pre.alpha.1"
  spec.add_dependency "socksify"
  spec.add_dependency "suma", "~> 0.5"
  # spec.metadata["rubygems_mfa_required"] = "true"
  # NOBODY UNCOMMENTS THIS WITHOUT EXPLAINING TO ME HOW TO USE MFA
end
