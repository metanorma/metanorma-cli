#!/usr/bin/env ruby
# frozen_string_literal: true

# grammar_census_report.rb — merge per-repo census fragments into the
# monthly grammar-census report (metanorma-iso#513).
#
# Usage: grammar_census_report.rb FRAGMENT_DIR REPORT.md
#
# Reads every *.yaml fragment written by grammar_census.rb and emits a
# markdown report: headline tally, per-repo totals, compile failures,
# and the pattern ranking (top 40).

require "yaml"

frag_dir, report_path = ARGV
abort "usage: grammar_census_report.rb FRAGMENT_DIR REPORT.md" unless frag_dir && report_path

frags = Dir[File.join(frag_dir, "**", "*.yaml")].sort.map { |f| YAML.safe_load(File.read(f, encoding: "UTF-8")) }
abort "no census fragments found under #{frag_dir}" if frags.empty?

date = Time.now.strftime("%Y-%m-%d")
total_docs = frags.sum { |f| f["docs"].size }
total_errs = frags.sum { |f| f["patterns"].values.sum }
patterns = Hash.new(0)
frags.each { |f| f["patterns"].each { |k, v| patterns[k] += v } }
fails = frags.flat_map do |f|
  f["docs"].select { |_, d| d["exit"] != 0 }.keys.map { |k| "#{f['repo']}/#{k}" }
end

lines = []
lines << "## Grammar census — #{date}"
lines << ""
lines << "Released metanorma stack; full `metanorma.yml` manifests. " \
         "Series context: https://github.com/metanorma/metanorma-iso/issues/513"
lines << ""
lines << "**#{total_docs} documents, #{total_errs} grammar errors, " \
         "#{patterns.size} distinct patterns, #{fails.size} compile failures.**"
lines << ""
lines << "| repo | docs | grammar errors | compile failures |"
lines << "|---|---|---|---|"
frags.sort_by { |f| -f["patterns"].values.sum }.each do |f|
  nfail = f["docs"].count { |_, d| d["exit"] != 0 }
  lines << "| #{f['repo']} | #{f['docs'].size} | #{f['patterns'].values.sum} | #{nfail} |"
end
unless fails.empty?
  lines << ""
  lines << "### Compile failures"
  lines << ""
  fails.each { |f| lines << "- `#{f}`" }
end
lines << ""
lines << "### Patterns by frequency (top 40)"
lines << ""
lines << "| hits | pattern |"
lines << "|---|---|"
patterns.sort_by { |_, v| -v }.first(40).each do |k, v|
  lines << "| #{v} | #{k.gsub('|', '\\|')} |"
end
lines << ""
lines << "🤖"

File.write(report_path, lines.join("\n") + "\n")
warn "[census] report: #{total_docs} docs, #{total_errs} errors, #{patterns.size} patterns"
