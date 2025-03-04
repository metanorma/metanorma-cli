lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "metanorma/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-cli"
  spec.version       = Metanorma::Cli::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Metanorma is the standard of standards; the metanorma gem allows you to create any standard document type supported by Metanorma."
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

  spec.add_development_dependency "debug"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-command", "~> 1.0.3"
  spec.add_development_dependency "rspec-core", "~> 3.4"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "vcr", "~> 6.1.0"
  spec.add_development_dependency "webmock"
  # need for dev because locally compiled metanorma-iso does not have css
  spec.add_development_dependency "rubocop", "~> 1"
spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "sassc-embedded"
  spec.add_development_dependency "xml-c14n"

  spec.add_runtime_dependency "metanorma-ietf", "~> 3.5.0"
  spec.add_runtime_dependency "metanorma-iso", "~> 3.0.0"
  spec.add_runtime_dependency "mnconvert"
  # spec.add_runtime_dependency "thor", "~> 1.0" # inherited from vectory
  # spec.add_runtime_dependency "metanorma-gb", "~> 1.5.0"
  spec.add_runtime_dependency "metanorma-cc", "~> 2.6.0"
  spec.add_runtime_dependency "metanorma-csa", "~> 2.6.0"
  spec.add_runtime_dependency "metanorma-iec", "~> 2.6.0"
  # spec.add_runtime_dependency 'metanorma-ribose', "~> 2.3.0"
  spec.add_runtime_dependency "metanorma-bipm", "~> 2.6.0"
  spec.add_runtime_dependency "metanorma-generic", "~> 3.0.0"
  spec.add_runtime_dependency "metanorma-standoc", "~> 3.0.0"
  # spec.add_runtime_dependency 'metanorma-mpfa', "~> 0.9.0"
  spec.add_runtime_dependency "git", "~> 1.5"
  spec.add_runtime_dependency "metanorma", "~> 2.1.0"
  spec.add_runtime_dependency "metanorma-iho", "~> 1.1.0"
  spec.add_runtime_dependency "metanorma-itu", "~> 2.6.0"
  # spec.add_runtime_dependency "metanorma-nist", "~> 2.6.0"
  spec.add_runtime_dependency "metanorma-ieee", "~> 1.4.0"
  spec.add_runtime_dependency "metanorma-jis", "~> 0.5.0"
  spec.add_runtime_dependency "metanorma-ogc", "~> 2.7.0"
  spec.add_runtime_dependency "metanorma-plateau", "~> 0.2.0"
  spec.add_runtime_dependency "relaton-cli", ">= 0.8.2"

  spec.add_runtime_dependency "socksify"
  # spec.metadata["rubygems_mfa_required"] = "true"
  # NOBODY UNCOMMENTS THIS WITHOUT EXPLAINING TO ME HOW TO USE MFA
end
