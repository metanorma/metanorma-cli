RESULTS = "spec/results".freeze

RSpec.describe "Collection" do
  around(:each) do |example|
    Dir.mktmpdir("rspec-") do |dir|
      FileUtils.cp Dir.glob("spec/fixtures/*"), dir
      Dir.chdir(dir) { example.run }
    end
  end

  it "render HTML from YAML" do
    Metanorma::Cli.start [
      "collection", "collection1.yml", "-x", "html", "-w", RESULTS, "-c", "collection_cover.html", "--no-install-fonts"
    ]
    expect_results
  end

  it "Render HTML from XML" do
    Metanorma::Cli.start [
      "collection", "collection1.xml", "-x", "html", "-w", RESULTS, "-c", "collection_cover.html", "--no-install-fonts"
    ]
    expect_results
  end

  def expect_results
    %w[index.html dummy.html rice-amd.final.html rice-en.final.html rice1-en.final.html].each do |file|
      expect(File.exist?(File.join(RESULTS, file))).to be_truthy
    end
  end
end
