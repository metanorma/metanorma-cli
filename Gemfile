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
    branch: "main"
gem "metanorma-core",
    github: "metanorma/metanorma-core",
    branch: "main"
gem "metanorma-document",
    github: "metanorma/metanorma-document",
    branch: "main"
gem "metanorma-iec",
    github: "metanorma/metanorma-iec",
    branch: "main"
gem "metanorma-iso",
    github: "metanorma/metanorma-iso",
    branch: "main"
gem "metanorma-itu",
    github: "metanorma/metanorma-itu",
    branch: "main"
gem "metanorma-ogc",
    github: "metanorma/metanorma-ogc",
    branch: "main"
gem "metanorma-standoc",
    github: "metanorma/metanorma-standoc",
    branch: "main"
gem "metanorma-taste",
    github: "metanorma/metanorma-taste",
    branch: "main"

# Fully private flavors resolve from their GitHub sources (the Packages
# registry only carries the retired 1.x line); the flavor loader
# discovers them generically from the bundle and open code never names
# them outside this dev bundle.
gem "metanorma-nist", github: "metanorma/metanorma-nist", branch: "main"
gem "metanorma-bsi", github: "metanorma/metanorma-bsi", branch: "main"

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
gem "lutaml", ">= 0.11.2"
gem "ogc-gml", "1.1.0"
gem "lutaml-model", "0.8.106" # LATEST RELEASE (glossarist 0.5 needs >= 0.8.22)
# Pin glossarist plugin: 0.3.10 freezes its preprocessor after
# initialization, breaking Asciidoctor compile in the cli suite.
gem "metanorma-plugin-glossarist", "~> 0.5" # standoc main needs the 0.5 preprocessor

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
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
# released suma 0.5.4 still pins svg_conform ~> 0.1.0, incompatible with
# standoc main (suma#127); main carries the fix, pending release
gem "suma", github: "metanorma/suma", branch: "main"
gem "metanorma-iso", github: "metanorma/metanorma-iso", branch: "main" # released 3.5.0 conflicts with metanorma-document main # released 3.4.2 still caps relaton-cli ~> 2.1
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main" # standoc main references Document::Components constants
gem "metanorma-utils", github: "metanorma/metanorma-utils", branch: "main" # released utils lacks GcBudget/deep_symbolize (main-only)
gem "isodoc", github: "metanorma/isodoc", branch: "main" # released isodoc caps relaton-render ~> 1.3

# the metagem's flavor zoo on mains: released flavors reference the retired 1.x render API
gem "metanorma", github: "metanorma/metanorma", branch: "main"
gem "metanorma-bipm", github: "metanorma/metanorma-bipm", branch: "main"
gem "metanorma-cc", github: "metanorma/metanorma-cc", branch: "main"
gem "metanorma-iec", github: "metanorma/metanorma-iec", branch: "main"
gem "metanorma-ieee", github: "metanorma/metanorma-ieee", branch: "main"
gem "metanorma-ietf", github: "metanorma/metanorma-ietf", branch: "main"
gem "metanorma-gb", github: "metanorma/metanorma-gb", branch: "main"
gem "metanorma-generic", github: "metanorma/metanorma-generic", branch: "main"
gem "metanorma-iho", github: "metanorma/metanorma-iho", branch: "main"
gem "metanorma-itu", github: "metanorma/metanorma-itu", branch: "main"
gem "metanorma-jis", github: "metanorma/metanorma-jis", branch: "main"
gem "metanorma-ogc", github: "metanorma/metanorma-ogc", branch: "main"
gem "metanorma-plateau", github: "metanorma/metanorma-plateau", branch: "main"
gem "metanorma-ribose", github: "metanorma/metanorma-ribose", branch: "main"
