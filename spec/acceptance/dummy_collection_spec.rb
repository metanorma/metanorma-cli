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

    expect(File).to exist("_site/index.html")
    expect(rendered_module_outputs).to eq(expected_module_outputs)
  end
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
end
# rubocop:enable RSpec/DescribeClass

def expected_module_outputs
  %w[doohickey-module gizmo-module widget-resource]
end

def rendered_module_outputs
  Dir.glob("_site/**/*.html").flat_map do |path|
    expected_module_outputs.select { |m| path.include?(m) }
  end.uniq.sort
end
