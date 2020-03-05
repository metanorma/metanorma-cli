
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "metanorma/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-cli"
  spec.version       = Metanorma::Cli::VERSION
  spec.authors       = ['Ribose Inc.']
  spec.email         = ['open.source@ribose.com']

  spec.summary       = %q{Metanorma is the standard of standards; the metanorma gem allows you to create any standard document type supported by Metanorma.}
  spec.description   = %q{Executable to process any Metanorma standard.}
  spec.homepage      = "https://www.metanorma.com"
  spec.license       = "BSD-2-Clause"

  spec.files         = Dir['**/*'].reject { |f| f.match(%r{^(test|spec|features|templates|.git)/|.(gem|gif|png|jpg|jpeg|xml|html|doc|pdf|dtd|ent)$}) }
  spec.files        += Dir.glob("templates/base/**", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  spec.extra_rdoc_files = %w[README.adoc LICENSE]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.4.0'

  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug", "~> 10.0"
  spec.add_development_dependency "rspec-command", "~> 1.0.3"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "rspec-core", "~> 3.4"

  spec.add_runtime_dependency "thor", "~> 0.20.3"
  spec.add_runtime_dependency "metanorma-iso", "~> 1.3.0"
  spec.add_runtime_dependency 'metanorma-ietf', "~> 2.0.0"
  spec.add_runtime_dependency 'metanorma-gb', "~> 1.3.0"
  spec.add_runtime_dependency 'metanorma-iec', "~> 1.0.0"
  spec.add_runtime_dependency 'metanorma-csd', "~> 1.3.0"
  spec.add_runtime_dependency 'metanorma-csa', "~> 1.4.0"
  #spec.add_runtime_dependency 'metanorma-rsd', "~> 1.1.0"
  spec.add_runtime_dependency 'metanorma-m3d', "~> 1.3.0"
  spec.add_runtime_dependency 'metanorma-acme', "~> 1.4.0"
  spec.add_runtime_dependency 'metanorma-standoc', "~> 1.3.0", ">= 1.3.18"
  #spec.add_runtime_dependency 'metanorma-mpfd', "~> 0.1.0"
  spec.add_runtime_dependency 'metanorma-un', "~> 0.3.1"
  spec.add_runtime_dependency 'metanorma-ogc', "~> 1.0.0"
  spec.add_runtime_dependency 'metanorma-nist', "~> 1.0.0"
  spec.add_runtime_dependency 'metanorma-itu', "~> 1.0.0"
  spec.add_runtime_dependency 'isodoc', "~> 1.0.0"
  spec.add_runtime_dependency 'metanorma', "~> 1.0.0"
  #spec.add_runtime_dependency 'nokogiri', ">= 1"
  spec.add_runtime_dependency "git", "~> 1.5"
  spec.add_runtime_dependency "relaton-cli"
end
