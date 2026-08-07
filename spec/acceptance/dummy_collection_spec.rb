# frozen_string_literal: true

RSpec.describe "Dummy ISO 10303 Collection" do
  # Fixture provenance: copied from metanorma/suma@4bf4891 (suma#108 merge).
  # See spec/fixtures/dummy_collection/SYNC.md for the sync procedure.
  around(:each) do |example|
    with_fixture_in_tmpdir("dummy_collection") { example.run }
  end

  it "renders the collection via metanorma site generate" do
    capture_stdout do
      Metanorma::Cli.start(%w[site generate --no-install-fonts])
    end

    expect(File.directory?("_site")).to be(true)
    expect(File.exist?("_site/index.html")).to be(true)

    # All three modules from collection.yml manifest must render — guards
    # against silent empty-site failures.
    %w[doohickey-module gizmo-module widget-resource].each do |doc|
      output = Dir.glob("_site/**/#{doc}*.html").first
      expect(output).to(
        be_present,
        "expected rendered HTML for `#{doc}' under _site/, got none",
      )
    end
  end
end
