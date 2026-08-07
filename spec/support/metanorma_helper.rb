require "fileutils"
require "tmpdir"

module Metanorma
  module Helper
    def stub_system_home_directory
      allow(Dir).to receive(:home)
        .and_return(Dir.tmpdir)
    end

    # Run +block+ inside a tmpdir populated with the named fixtures.
    # All +fixture_paths+ are relative to <tt>spec/fixtures/</tt>.
    #
    #   with_fixture_in_tmpdir("dummy_collection") { ... }
    #   with_fixture_in_tmpdir("collection1.yml",
    #                          "collection_cover.html") { ... }
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
