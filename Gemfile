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
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main" # released 3.4.2 still caps relaton-cli ~> 2.1
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main" # standoc main references Document::Components constants
gem "metanorma-utils", github: "metanorma/metanorma-utils", branch: "main" # released utils lacks GcBudget/deep_symbolize (main-only)
