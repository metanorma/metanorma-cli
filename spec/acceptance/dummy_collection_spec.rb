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
  #
  # The run's own health is asserted, not just its products: a compile
  # that hits a fatal error (metanorma's clean_abort) prints "FATAL
  # ERRORS" on stderr and raises SystemExit(1) through the suma Thor
  # extension -- which used to escape the example while its own
  # assertions stayed green, leaving CI a bare exit 1 with "0 failures"
  # (metanorma-plugin-lutaml figure staging regression). Both output
  # streams are checked for the fatal banner, the exit status is pinned
  # to zero, and the schema document carrying the fixture's only
  # EXPRESS-G figure is checked to actually render it.
  # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
  it "renders the collection via metanorma site generate" do
    output = errors = nil
    output = capture_stdout do
      errors = capture_stderr do
        begin
          Metanorma::Cli.start(
            %w[site generate --no-install-fonts --output-dir _site],
          )
        rescue SystemExit => e
          # The command exits even on success; a nonzero status is the
          # fatal-error mode this example exists to expose.
          expect(e.status).to be_zero
        end
      end
    end

    expect(output).not_to include("FATAL ERRORS")
    expect(errors).not_to include("FATAL ERRORS")

    expect(File).to exist("_site/index.html")
    expect(rendered_schema_docs).to eq(expected_schema_docs)

    # The gizmo_arm schema is the fixture's only figure carrier
    # (schemas/modules/gizmo/armexpg1.svg beside its .exp): the compiled
    # document must embed it, inlined or as a data URI -- never dropped.
    html = File.read("_site/schema_docs/gizmo_arm/doc_gizmo_arm.html")
    expect(html).to match(%r{<svg|data:image/svg\+xml})
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
