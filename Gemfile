Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gem "metanorma-nist", github: "metanorma/metanorma-nist", branch: "main"
gem "metanorma-bsi", github: "metanorma/metanorma-bsi", branch: "main"

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
