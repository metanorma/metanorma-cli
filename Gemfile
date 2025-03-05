Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

source "https://rubygems.pkg.github.com/metanorma" do
  gem "metanorma-nist"
end

gemspec

group :development do
  gem "debug"
  gem "pry"
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"
  gem "rspec-command", "~> 1.0.3"
  gem "rspec-core", "~> 3.4"
  gem "rubocop", "~> 1"
  gem "rubocop-performance"
  # need for dev because locally compiled metanorma-iso does not have css
  gem "sassc-embedded"
  gem "simplecov", "~> 0.15"
  gem "vcr", "~> 6.1.0"
  gem "webmock"
  gem "xml-c14n"
end

begin
  eval_gemfile("Gemfile.devel")
rescue StandardError
  nil
end
