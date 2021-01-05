RSpec.describe "Collection" do
  it "render HTML from YAML" do
    of = "spec/results"
    Metanorma::Cli.start [
      "collection", "spec/fixtures/collection1.yml", "-x", "html",
      "-w", of, "-c", "spec/fixtures/collection_cover.html",
      "--no-install-fonts"
    ]
    expect(File.exist?("spec/results/index.html")).to be true
    expect(File.exist?("spec/results/dummy.html")).to be true
    expect(File.exist?("spec/results/rice-amd.final.html")).to be true
    expect(File.exist?("spec/results/rice-en.final.html")).to be true
    expect(File.exist?("spec/results/rice1-en.final.html")).to be true
    FileUtils.rm_rf of
  end

  it "Render HTML from XML" do
    of = "spec/results"
    Metanorma::Cli.start [
      "collection", "spec/fixtures/collection1.xml", "-x", "html",
      "-w", of, "-c", "spec/fixtures/collection_cover.html",
      "--no-install-fonts"
    ]
    expect(File.exist?("spec/results/index.html")).to be true
    expect(File.exist?("spec/results/dummy.html")).to be true
    expect(File.exist?("spec/results/rice-amd.final.html")).to be true
    expect(File.exist?("spec/results/rice-en.final.html")).to be true
    expect(File.exist?("spec/results/rice1-en.final.html")).to be true
    FileUtils.rm_rf of
  end
end
