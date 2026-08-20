#!/usr/bin/env ruby
# frozen_string_literal: true

# grammar_census.rb — Semantic-XML grammar-error census over one samples
# repo. Part of the monthly grammar census (metanorma-iso#513).
#
# Usage: grammar_census.rb REPO_PATH FLAVOR OUTPUT.yaml
#
# Compiles every .adoc discovered in the repo's metanorma.yml source.files
# (the full manifest, deliberately not metanorma.test.yml: the census
# measures the whole fleet) with `metanorma compile FILE -x xml -t FLAVOR`,
# harvests "Metanorma XML Syntax" (STANDOC_7) rows from each .err.html,
# normalizes messages into recurring patterns, and writes a per-repo
# census fragment.
#
# Source-file discovery:
#   - .adoc entries are compiled directly.
#   - .yml/.yaml entries are treated as collection manifests and recursed:
#       manifest.docref[*].file      → sub-collection manifest (recurse)
#       manifest.docref[*].fileref   → leaf; .adoc compiled, others skipped
#       manifest.docref[*].docref    → nested docref array (recurse in place)
#   - Cycle-safe via a visited-set on absolute collection paths.

require "yaml"
require "fileutils"

# Source-file discovery for the census. Split into a module so unit tests
# can require this file and exercise discovery without invoking the
# metanorma-compile main body.
module Collector
  module_function

  # Discover .adoc paths (relative to repo root) by walking source.files,
  # recursing into any collection manifests. Cycle-safe.
  def discover_adocs(repo_root, source_files)
    visited = Set.new
    adocs = []
    source_files.each do |rel|
      discover_entry(repo_root, rel, ".", visited, adocs)
    end
    adocs.uniq.sort
  end

  # Handle one source entry (file or collection manifest) relative to `base`
  # (itself relative to repo_root).
  def discover_entry(repo_root, rel, base, visited, adocs)
    full_rel = normalize_rel(base, rel)
    return if full_rel.nil? || full_rel == ""

    if full_rel.end_with?(".adoc")
      adocs << full_rel
    elsif full_rel.end_with?(".yml", ".yaml")
      walk_collection(repo_root, full_rel, visited, adocs)
    end
  end

  # Walk a collection manifest, descending into docref entries.
  def walk_collection(repo_root, collection_rel, visited, adocs)
    abs = File.expand_path(collection_rel, repo_root)
    return unless File.exist?(abs)
    return if visited.include?(abs)

    visited << abs
    data = YAML.safe_load_file(abs)
    docrefs = data&.dig("manifest", "docref")
    return unless docrefs.is_a?(Array)

    base = File.dirname(collection_rel)
    docrefs.each { |ref| process_ref(ref, base, repo_root, visited, adocs) }
  end

  # Process one manifest.docref entry: descend if it has a sub-collection
  # `file`, add leaf if it has a `.adoc` `fileref`, recurse if it nests.
  def process_ref(ref, base, repo_root, visited, adocs)
    return unless ref.is_a?(Hash)

    discover_entry(repo_root, ref["file"], base, visited, adocs) if ref["file"]
    add_adoc_if_leaf(ref["fileref"], base, adocs)
    return unless ref["docref"].is_a?(Array)

    ref["docref"].each do |inner|
      process_nested(inner, base, repo_root, visited, adocs)
    end
  end

  # Recurse into a nested `docref:` array on the same collection manifest
  # (e.g. level: document groupings inside a top-level docref entry).
  def walk_nested_docref(docrefs, base, repo_root, visited, adocs)
    docrefs.each do |inner|
      process_nested(inner, base, repo_root, visited, adocs)
    end
  end

  def process_nested(inner, base, repo_root, visited, adocs)
    return unless inner.is_a?(Hash)

    add_adoc_if_leaf(inner["fileref"], base, adocs)
    if inner["file"]
      discover_entry(repo_root, inner["file"], base, visited, adocs)
    end
    return unless inner["docref"].is_a?(Array)

    inner["docref"].each do |i|
      process_nested(i, base, repo_root, visited, adocs)
    end
  end

  # If the given fileref resolves to a `.adoc` under base, add it to adocs.
  def add_adoc_if_leaf(fileref, base, adocs)
    return unless fileref

    leaf = normalize_rel(base, fileref)
    adocs << leaf if leaf&.end_with?(".adoc")
  end

  # Join `base` (a relative dir from repo_root) with `rel` (a path that may
  # contain .. segments), then normalise to a repo-root-relative posix path.
  def normalize_rel(base, rel)
    return nil if rel.nil? || rel == ""

    joined = base == "." ? rel : File.join(base, rel)
    File.expand_path(joined, "/").delete_prefix("/")
  end
end

if $PROGRAM_NAME == __FILE__
  repo, flavor, out_path = ARGV
  (repo && flavor && out_path) or
    abort "usage: grammar_census.rb REPO_PATH FLAVOR OUTPUT.yaml"
  repo = File.expand_path(repo)
  repo_name = File.basename(repo)

  manifest = YAML.safe_load_file(File.join(repo, "metanorma.yml"))
  files = manifest.dig("metanorma", "source", "files") ||
    abort("no source.files in metanorma.yml")

  docs = Collector.discover_adocs(repo, files)

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
end
