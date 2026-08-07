# frozen_string_literal: true

RESULTS = "spec/results".freeze

# Fixtures required by collection1.{yml,xml} (filerefs + cover + site config).
# Listed explicitly so the dependency surface is visible; was previously
# Dir.glob("spec/fixtures/*") (greedy, copied everything).
COLLECTION_FIXTURES = %w[
  collection1.yml
  collection1.xml
  collection_cover.html
  metanorma.yml
  dummy.xml
  rice-amd.final.xml
  rice-en.final.xml
  rice1-en.final.xml
].freeze

RSpec.describe "Collection" do
  describe "collection" do
    it "render HTML from YAML" do
      run_metanorma_collection("collection1.yml")
      expect_generated_files_to_match_expectations
    end

    it "Render HTML from XML" do
      run_metanorma_collection("collection1.xml")
      expect_generated_files_to_match_expectations
    end
  end

  around(:each) do |example|
    with_fixture_in_tmpdir(*COLLECTION_FIXTURES) { example.run }
  end

  def run_metanorma_collection(filename)
    command = %W(
      collection #{filename}
      -x html
      -w #{RESULTS}
      -c collection_cover.html
      --no-install-fonts
    )
    capture_stdout { Metanorma::Cli.start(command) }
  end

  def expect_generated_files_to_match_expectations
    expected_files.each do |file|
      warn File.join(RESULTS, file)
      expect(File.exist?(File.join(RESULTS, file))).to be_truthy
    end
  end

  def expected_files
    %w[index.html rice-amd.final.html rice-en.final.html rice1-en.final.html]
  end
end
