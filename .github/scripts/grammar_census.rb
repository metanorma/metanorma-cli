#!/usr/bin/env ruby
# frozen_string_literal: true

# grammar_census.rb — Semantic-XML grammar-error census over one samples
# repo. Part of the monthly grammar census (metanorma-iso#513).
#
# Usage: grammar_census.rb REPO_PATH FLAVOR OUTPUT.yaml
#
# Compiles every .adoc in the repo's metanorma.yml source.files (the full
# manifest, deliberately not metanorma.test.yml: the census measures the
# whole fleet) with `metanorma compile FILE -x xml -t FLAVOR`, harvests
# "Metanorma XML Syntax" (STANDOC_7) rows from each .err.html, normalizes
# messages into recurring patterns, and writes a per-repo census fragment.

require "yaml"
require "fileutils"

repo, flavor, out_path = ARGV
(repo && flavor && out_path) or
  abort "usage: grammar_census.rb REPO_PATH FLAVOR OUTPUT.yaml"
repo = File.expand_path(repo)
repo_name = File.basename(repo)

manifest = YAML.safe_load_file(File.join(repo, "metanorma.yml"))
files = manifest.dig("metanorma", "source", "files") ||
  abort("no source.files in metanorma.yml")
docs = files.select { |f| f.end_with?(".adoc") }

UUID_RE =
  /\b_?\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\b/

def normalize(msg)
  msg.gsub(/^XML Line \d+:?\d*:?\s*/, "")
    .gsub(/"[^"]*"/) { |q| q.length > 40 ? '"…"' : q }
    .gsub(UUID_RE, "«id»")
    .strip
end

# strip markup repeatedly, so that nested/split tags cannot survive one pass
def strip_tags(str)
  str = str.gsub(/<[^>]*>/, "") while str.match?(/<[^>]*>/)
  str
end

def row_message(row)
  cells = row.scan(%r{<t[dh][^>]*>(.*?)</t[dh]>}m).flatten
  strip_tags(cells[3].to_s).strip
end

def harvest_err_html(path)
  html = File.read(path, encoding: "UTF-8")
  html.scan(%r{<tr[^>]*>(.*?)</tr>}m).map(&:first)
    .select { |r| r.include?("STANDOC_7") }
    .map { |r| row_message(r) }.reject(&:empty?)
end

census = { "repo" => repo_name, "flavor" => flavor, "docs" => {},
           "patterns" => Hash.new(0) }

docs.each do |rel|
  src = File.join(repo, rel)
  unless File.exist?(src)
    census["docs"][rel] = { "exit" => nil, "grammar_errors" => 0,
                            "note" => "MISSING" }
    next
  end
  outdir = File.join(Dir.pwd, "census-out", repo_name,
                     rel.sub(/\.adoc$/, "").gsub("/", "--"))
  FileUtils.mkdir_p(outdir)
  log = File.join(outdir, "compile.log")
  ok = system("bundle", "exec", "metanorma", "compile", rel, "-x", "xml",
              "-t", flavor, "--agree-to-terms", "--no-install-fonts",
              "-o", outdir, chdir: repo, out: log, err: log)
  errs = Dir[File.join(outdir, "*.err.html")]
    .flat_map { |f| harvest_err_html(f) }
  errs.each { |m| census["patterns"][normalize(m)] += 1 }
  census["docs"][rel] = { "exit" => ok ? 0 : 1,
                          "grammar_errors" => errs.size }
  warn "[census] #{repo_name}/#{rel}: exit=#{ok ? 0 : 1} " \
       "grammar_errors=#{errs.size}"
end

census["patterns"] = census["patterns"].sort_by { |_, v| -v }.to_h
FileUtils.mkdir_p(File.dirname(out_path))
File.write(out_path, census.to_yaml)
warn "[census] #{repo_name}: #{census['docs'].size} docs, " \
     "#{census['patterns'].values.sum} errors, " \
     "#{census['patterns'].size} patterns"
