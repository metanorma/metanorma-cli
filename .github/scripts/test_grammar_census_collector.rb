# frozen_string_literal: true

# Unit tests for the collection-manifest recursion in grammar_census.rb.
# Run directly:  ruby .github/scripts/test_grammar_census_collector.rb
#
# Builds synthetic source trees under Dir.mktmpdir and asserts that
# Collector.discover_adocs walks metanorma.yml → collection.yml →
# document.adoc correctly, including nested docref arrays, .. segments,
# cycle protection, and deduplication.

require "tmpdir"
require "fileutils"
require "minitest/autorun"

require_relative "grammar_census"

class TestCollector < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir("census-collector-")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def write(rel, body)
    path = File.join(@tmp, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, body)
  end

  def manifest(files)
    { "metanorma" => { "source" => { "files" => files } } }.to_yaml
  end

  def collection_with_files(files_array)
    { "manifest" => { "docref" => files_array } }.to_yaml
  end

  def discover(files)
    File.write(File.join(@tmp, "metanorma.yml"), manifest(files))
    Collector.discover_adocs(@tmp, files)
  end

  def test_flat_adoc_list
    write("a.adoc", "x")
    write("b.adoc", "x")
    assert_equal %w[a.adoc b.adoc], discover(%w[a.adoc b.adoc])
  end

  def test_skips_non_adoc_at_top_level
    write("a.adoc", "x")
    write("notes.txt", "x")
    assert_equal %w[a.adoc], discover(%w[a.adoc notes.txt])
  end

  def test_collection_with_fileref_adoc
    write("documents/gizmo/document.adoc", "x")
    write("collection.yml",
          collection_with_files([{ "fileref" => "documents/gizmo/document.adoc",
                                   "identifier" => "g1" }]))
    assert_equal %w[documents/gizmo/document.adoc],
                 discover(%w[collection.yml])
  end

  def test_collection_skips_non_adoc_fileref
    write("schemas/gizmo/arm.exp", "x")
    write("collection.yml",
          collection_with_files([{ "fileref" => "schemas/gizmo/arm.exp",
                                   "identifier" => "g_arm",
                                   "attachment" => true }]))
    assert_equal [], discover(%w[collection.yml])
  end

  def test_collection_with_subcollection_file
    write("documents/gizmo/document.adoc", "x")
    write("documents/gizmo/collection.yml",
          collection_with_files([{ "fileref" => "document.adoc",
                                   "identifier" => "g1" }]))
    write("collection.yml",
          collection_with_files([{ "file" =>
                                     "documents/gizmo/collection.yml" }]))
    assert_equal %w[documents/gizmo/document.adoc],
                 discover(%w[collection.yml])
  end

  def test_nested_docref_array
    write("documents/gizmo/document.adoc", "x")
    write("collection.yml",
          { "manifest" => {
            "docref" => [
              { "level" => "document", "docref" => [
                { "fileref" => "documents/gizmo/document.adoc",
                  "identifier" => "g1" },
              ] },
            ],
          } }.to_yaml)
    assert_equal %w[documents/gizmo/document.adoc],
                 discover(%w[collection.yml])
  end

  def test_dotdot_segment_in_fileref
    write("plain_schemas/gizmo/arm.exp", "x")
    write("documents/gizmo/collection.yml",
          { "manifest" => {
            "docref" => [
              { "fileref" => "../../plain_schemas/gizmo/arm.exp",
                "identifier" => "g_arm", "attachment" => true },
            ],
          } }.to_yaml)
    write("collection.yml",
          collection_with_files([{ "file" =>
                                     "documents/gizmo/collection.yml" }]))
    assert_equal [], discover(%w[collection.yml])
  end

  def test_cycle_protection
    write("documents/gizmo/document.adoc", "x")
    # a → b → a
    write("a.yml",
          collection_with_files([{ "file" => "b.yml" }]))
    write("b.yml",
          collection_with_files([{ "file" => "a.yml" },
                                 { "fileref" => "documents/gizmo/document.adoc",
                                   "identifier" => "g1" }]))
    assert_equal %w[documents/gizmo/document.adoc],
                 discover(%w[a.yml])
  end

  def test_dedup_when_same_adoc_referenced_twice
    write("doc.adoc", "x")
    write("c1.yml",
          collection_with_files([{ "fileref" => "doc.adoc",
                                   "identifier" => "d1" }]))
    # Same adoc discovered via top-level + collection
    assert_equal %w[doc.adoc], discover(%w[doc.adoc c1.yml])
  end

  def test_missing_collection_is_silently_skipped
    write("a.adoc", "x")
    # missing.yml does not exist on disk — must not abort, must not contribute
    assert_equal %w[a.adoc], discover(%w[a.adoc missing.yml])
  end
end
