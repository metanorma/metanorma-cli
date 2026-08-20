Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

source "https://rubygems.pkg.github.com/metanorma" do
  gem "metanorma-nist"
  gem "metanorma-bsi"
end

gemspec

# TEMPORARY cross-PR branch pins for the flavor-table restructure wave
# (one PR per gem; revert each once its PR merges):
#   metanorma-core#18, metanorma-document#45, metanorma#591,
#   metanorma-iso#1618, metanorma-standoc#1232, metanorma-taste#204
gem "metanorma-core", github: "metanorma/metanorma-core", branch: "feat/flavor-table"
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "feat/model-validation-l1-declarations"
gem "metanorma", github: "metanorma/metanorma", branch: "feat/flavors-table"
gem "metanorma-iso", github: "metanorma/metanorma-iso", branch: "feat/model-validation-migration"
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "feat/move-standard-document"
gem "metanorma-taste", github: "metanorma/metanorma-taste", branch: "feat/flavor-registry-integration"
gem "metanorma-itu", github: "metanorma/metanorma-itu", branch: "feat/move-itu-document"
gem "metanorma-iec", github: "metanorma/metanorma-iec", branch: "feat/move-iec-document"
gem "metanorma-ogc", github: "metanorma/metanorma-ogc", branch: "feat/move-ogc-document"


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
