Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

source "https://rubygems.pkg.github.com/metanorma" do
  gem "metanorma-bsi"
  gem "metanorma-nist"
end

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
