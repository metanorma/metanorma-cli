
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "metanorma-cli/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-cli"
  spec.version       = Metanorma::CLI::VERSION
  spec.authors       = ['Ribose Inc.']
  spec.email         = ['open.source@ribose.com']

  spec.summary       = %q{Metanorma is the standard of standards; the metanorma gem allows you to create any standard document type supported by Metanorma.}
  spec.description   = %q{Executable to process any Metanorma standard.}
  spec.homepage      = "https://github.com/riboseinc/metanorma"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.extra_rdoc_files = %w[README.adoc LICENSE]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug", "~> 10.0"
  spec.add_development_dependency "rspec-command", "~> 1.0.3"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency 'rspec-core', "~> 3.4"


  spec.add_runtime_dependency 'metanorma-iso', "~> 1.0.6"
  spec.add_runtime_dependency 'asciidoctor-rfc', "~> 0.9.0"
  spec.add_runtime_dependency 'metanorma-gb', "~> 1.0.5"
  spec.add_runtime_dependency 'metanorma-csd', "~> 1.0.5"
  spec.add_runtime_dependency 'metanorma-csand', "~> 1.0.5"
  spec.add_runtime_dependency 'metanorma-rsd', "~> 1.0.5"
  spec.add_runtime_dependency 'metanorma-m3d', "~> 1.0.6"
  spec.add_runtime_dependency 'metanorma-acme', "~> 1.0.1"
  spec.add_runtime_dependency 'metanorma-standoc', "~> 1.0.6"
  spec.add_runtime_dependency 'isodoc', "~> 0.9.0"
  spec.add_runtime_dependency 'metanorma', "~> 0.2.6"
end
