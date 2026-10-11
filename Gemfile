Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

source "https://rubygems.pkg.github.com/metanorma" do
  gem "metanorma-nist"
  gem "metanorma-bsi"
end

gemspec

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

gem "metanorma-oiml", github: "metanorma/metanorma-oiml", branch: "main" # never published to rubygems
gem "metanorma-iso", github: "metanorma/metanorma-iso", branch: "main"
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main"

gem "metanorma-mirror", github: "metanorma/metanorma-mirror", branch: "main" # the mirror sub-gem is main-only
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main" # released standoc lacks Metanorma::Standoc::Document
gem "metanorma-utils", github: "metanorma/metanorma-utils", branch: "main" # released utils lacks GcBudget/deep_symbolize (main-only)
# flavor CitationStyle facades need the 3.x pre engine; bundler-prefer-stable otherwise resolves 1.3
gem "relaton-render", ">= 3.0.0.pre.alpha.43"
gem "relaton-cli", ">= 3.0.0.pre.alpha"
