Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

source "https://rubygems.pkg.github.com/metanorma" do
  gem "metanorma-nist"
end

gemspec

begin
  eval_gemfile("Gemfile.devel")
rescue StandardError
  nil
end
