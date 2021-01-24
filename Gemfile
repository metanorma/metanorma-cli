Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec

gem "metanorma", git: "https://github.com/metanorma/metanorma.git", branch: "feature/use-option-variables-without-hyphens"

if File.exist? 'Gemfile.devel'
  eval File.read('Gemfile.devel'), nil, 'Gemfile.devel' # rubocop:disable Security/Eval
end
