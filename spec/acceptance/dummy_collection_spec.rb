# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
RSpec.describe "Dummy ISO 10303 Collection" do
  # Fixture provenance: copied from metanorma/suma@4bf4891 (suma#108 merge).
  # See spec/fixtures/dummy_collection/SYNC.md for the sync procedure.
  # with_fixture_in_tmpdir nests the fixture one level down, so the block
  # enters the collection root where metanorma.yml lives.
  around do |example|
    with_fixture_in_tmpdir("dummy_collection") do
      Dir.chdir("dummy_collection") { example.run }
    end
  end

  # The schema-bearing manifest routes through the suma pipeline
  # (SchemaSiteDetector dispatch), which compiles the fixture's schemas
  # into the module documents the collection attaches.
  # --output-dir is explicit: the command's default resolves against the
  # process start directory, not the fixture tmpdir the example chdirs into.
  # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
  it "renders the collection via metanorma site generate" do
    capture_stdout do
      Metanorma::Cli.start(
        %w[site generate --no-install-fonts --output-dir _site],
      )
    end

    expect(File).to exist("_site/index.html")
    expect(rendered_schema_docs).to eq(expected_schema_docs)
  end
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
end
# rubocop:enable RSpec/DescribeClass

def expected_schema_docs
  %w[doohickey_arm doohickey_mim gadget_schema gizmo_arm gizmo_mim
     widget_schema]
end

def rendered_schema_docs
  Dir.glob("_site/schema_docs/*/doc_*.html").flat_map do |path|
    expected_schema_docs.select { |schema| path.include?("/#{schema}/") }
  end.uniq.sort
end
