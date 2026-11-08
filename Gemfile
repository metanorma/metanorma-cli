Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"


gemspec

# Private flavors (nist, bsi) are intentionally absent: their sources are
# not readable without credentials, so any unauthenticated fresh resolve
# fails. The flavor loader is still tested against them via stubbed
# specs, and the grammar census installs them with GitHub Packages auth.

gem "pubid", "~> 2.0" # 2.0.0 released; the git source now carries the 2.1 pre line

# The git gem's 6.0.0 removed clone's `:path` and the Repository#branches
# collection (template + fontist-repo setup crashes). The template code is
# ported on this branch; fontist still needs its own port and release, so
# ride the 5.x line until then.
# Floor fontist at the variable-font indexing fix (fontist#531/#532):
# google/fira_code and friends went variable-only, and anything below
# 3.0.31 registers a fresh install under its default instance family
# only, so Manifest locations lookups miss "Fira Code" and friends.
gem "fontist", "~> 3.0.32"
# git 6: the template clone port landed (git_template.rb gates on
# Git::VERSION), and fontist 3.0.32+ requires git ~> 6.0 itself, so the
# 5.x ride-along is over.
gem "git", "~> 6.0"

# Force newer xmi (lutaml 0.9.43 pins xmi ~> 0.3.20; xmi 0.7+ moved
# the XML adapter to a path compatible with lutaml-model 0.8.x).
# Conflict with lutaml's pin is resolved by also pinning lutaml to a
# version that no longer enforces it.
gem "xmi", "~> 0.7"
gem "lutaml", ">= 0.11.2"
gem "ogc-gml", "1.1.0"
gem "lutaml-model", "~> 0.8.164" # the fleet convention: pessimistic floor at the latest patch
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
gem "metanorma-core", "~> 0.2.7"
gem "metanorma-taste", "~> 1.1"
gem "metanorma-standoc", "~> 3.5"
gem "metanorma-iso", "~> 3.5"
gem "metanorma-document", "~> 0.5.4"
gem "metanorma-utils", "~> 2.0"
gem "isodoc", "~> 3.7"

# the metagem's flavor zoo
gem "metanorma", "~> 2.5"
gem "metanorma-bipm", "~> 2.9"
gem "metanorma-cc", "~> 2.9"
gem "metanorma-iec", "~> 2.9"
gem "metanorma-ieee", "~> 1.7"
gem "metanorma-ietf", "~> 3.7"
gem "metanorma-gb", "~> 1.5"
gem "metanorma-generic", "~> 3.5"
gem "metanorma-iho", "~> 1.4"
gem "metanorma-itu", "~> 2.9"
gem "metanorma-jis", "~> 1.2"
gem "metanorma-ogc", "~> 2.10"
gem "metanorma-oiml", "~> 0.1"
gem "metanorma-plateau", "~> 1.3"
gem "metanorma-ribose", "~> 2.9"
