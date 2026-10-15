# frozen_string_literal: true

require "bundler/setup"
require "json"
require "digest"
require "plurimath"

spec = Gem.loaded_specs.fetch("plurimath")
source = spec.full_gem_path
head = IO.popen(["git", "-C", source, "rev-parse", "HEAD"], &:read).strip
abort "Cannot verify loaded Plurimath source" unless $?.success?
records = Bundler.load.specs.reject { |item| item.name == "plurimath" }.map do |item|
  origin = item.source
  record = { name: item.name, version: item.version.to_s, platform: item.platform.to_s,
             source_type: origin.class.name }
  if origin.is_a?(Bundler::Source::Git)
    record[:uri] = origin.uri
    record[:revision] = origin.revision
  elsif origin.is_a?(Bundler::Source::Path)
    record[:path] = origin.path.to_s.gsub(Dir.pwd, "<CLI>")
  elsif origin.respond_to?(:remotes)
    record[:remotes] = origin.remotes.map(&:to_s).sort
  end
  record
end.sort_by { |item| [item[:name], item[:platform]] }
payload = JSON.generate(
  ruby: RUBY_DESCRIPTION,
  plurimath: { version: spec.version.to_s, source: source, sha: head,
               parse_source: Plurimath::Math.method(:parse).source_location },
  dependencies: records,
  dependency_fingerprint: Digest::SHA256.hexdigest(JSON.generate(records)),
)

File.write(ARGV.fetch(0), payload)
