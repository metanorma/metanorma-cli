# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module Metanorma
  # Shared helper for acceptance specs that need a fixture copied into an
  # isolated tmpdir before running metanorma. Supports both flat-file and
  # subtree fixtures via the same path.
  module FixtureTmpdir
    # Run +block+ inside a tmpdir populated with the named fixtures.
    # All +fixture_paths+ are relative to <tt>spec/fixtures/</tt>.
    #
    #   with_fixture_in_tmpdir("dummy_collection") { ... }   # subtree
    #   with_fixture_in_tmpdir("collection1.yml",
    #                          "collection_cover.html") { ... }   # flat
    #
    # Directories are copied recursively (subtree); files copied as-is.
    # The block runs with +Dir.pwd+ set to the tmpdir; restored on exit.
    def with_fixture_in_tmpdir(*fixture_paths, &block)
      Dir.mktmpdir("rspec-fixture-") do |tmpdir|
        fixture_paths.each do |rel|
          src = File.join("spec/fixtures", rel)
          dst = File.join(tmpdir, rel)
          FileUtils.mkdir_p(File.dirname(dst))
          if File.directory?(src)
            FileUtils.cp_r(File.join(src, "."), dst)
          else
            FileUtils.cp(src, dst)
          end
        end
        Dir.chdir(tmpdir, &block)
      end
    end
  end
end
