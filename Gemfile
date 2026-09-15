Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec

# TEMPORARY cross-PR pins for the flavor-table restructure wave.
# Revert each once its PR merges (core#18 document#45 metanorma#591
# iso#1618 standoc#1232 taste#204 itu/iec/ogc migration PRs).
gem "metanorma",
    github: "metanorma/metanorma",
    branch: "feat/flavors-table"
gem "metanorma-core",
    github: "metanorma/metanorma-core",
    branch: "feat/flavor-table"
gem "metanorma-document",
    github: "metanorma/metanorma-document",
    branch: "feat/model-validation-l1-declarations"
gem "metanorma-iec",
    github: "metanorma/metanorma-iec",
    branch: "feat/move-iec-document"
gem "metanorma-iso",
    github: "metanorma/metanorma-iso",
    branch: "feat/model-validation-migration"
gem "metanorma-itu",
    github: "metanorma/metanorma-itu",
    branch: "feat/move-itu-document"
gem "metanorma-ogc",
    github: "metanorma/metanorma-ogc",
    branch: "feat/move-ogc-document"
gem "metanorma-standoc",
    github: "metanorma/metanorma-standoc",
    branch: "feat/move-standard-document"
gem "metanorma-taste",
    github: "metanorma/metanorma-taste",
    branch: "feat/flavor-registry-integration"

gem "isodoc",
    github: "metanorma/isodoc",
    branch: "rt-pubid-2-migration"
gem "relaton-cli", ">= 2.2.0.pre.alpha.1"
gem "relaton-bib", "~> 2.2.0.pre.alpha.1"
gem "pubid",
    github: "pubid/pubid",
    branch: "main"

# Cap lutaml-model < 0.8.20: 0.8.20 relocates the XML adapter directory
# (xmi and other transitive gems still require the old path). The wave's
# other gems (document/iso) also pin ~> 0.8.0; this avoids the imminent
# 0.8.20 yank.
# Force newer xmi (lutaml 0.9.43 pins xmi ~> 0.3.20; xmi 0.7+ moved
# the XML adapter to a path compatible with lutaml-model 0.8.x).
# Conflict with lutaml's pin is resolved by also pinning lutaml to a
# version that no longer enforces it.
gem "xmi", "~> 0.7"
gem "lutaml", "~> 0.10.0"
gem "ogc-gml", "1.1.0"
gem "lutaml-model", "~> 0.8.0", "< 0.8.20"
# Pin glossarist plugin: 0.3.10 freezes its preprocessor after
# initialization, breaking Asciidoctor compile in the cli suite.
gem "metanorma-plugin-glossarist", "0.3.9"

group :development do
  gem "debug"
  gem "pry"
  gem "rake"
  gem "rspec"
  gem "rspec-command"
  gem "rspec-core"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"
  # need for dev because locally compiled metanorma-iso does not have css
  gem "sassc-embedded"
  gem "simplecov"
  gem "vcr"
  gem "webmock"
  gem "xml-c14n"
end

begin
  eval_gemfile("Gemfile.devel")
rescue StandardError
  nil
end

# Wave-branch pins replacing the private-registry releases (their
# released versions still require pubid-bsi/nist, incompatible with the
# pubid monogem pin above).
gem "metanorma-bipm",
    github: "metanorma/metanorma-bipm",
    branch: "feat/ocp-adoption"
gem "metanorma-bsi",
    github: "metanorma/metanorma-bsi",
    branch: "feat/ocp-adoption"
gem "metanorma-generic",
    github: "metanorma/metanorma-generic",
    branch: "feat/ocp-adoption"
gem "metanorma-nist",
    github: "metanorma/metanorma-nist",
    branch: "feat/ocp-adoption"
gem "metanorma-ieee",
    github: "metanorma/metanorma-ieee",
    branch: "feat/ocp-adoption"
gem "metanorma-jis",
    github: "metanorma/metanorma-jis",
    branch: "feat/ocp-adoption"
gem "metanorma-plateau",
    github: "metanorma/metanorma-plateau",
    branch: "feat/ocp-adoption"
