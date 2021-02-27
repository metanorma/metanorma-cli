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
    expect(File.exist?("#{RESULTS}/index.html")).to be true
    expect(File.exist?("#{RESULTS}/dummy.html")).to be true
    expect(File.exist?("#{RESULTS}/rice-amd.final.html")).to be true
    expect(File.exist?("#{RESULTS}/rice-en.final.html")).to be true
    expect(File.exist?("#{RESULTS}/rice1-en.final.html")).to be true
  end

  it "Render HTML from XML" do
    Metanorma::Cli.start [
      "collection", "collection1.xml", "-x", "html", "-w", RESULTS, "-c", "collection_cover.html", "--no-install-fonts"
    ]
    expect(File.exist?("#{RESULTS}/index.html")).to be true
    expect(File.exist?("#{RESULTS}/dummy.html")).to be true
    expect(File.exist?("#{RESULTS}/rice-amd.final.html")).to be true
    expect(File.exist?("#{RESULTS}/rice-en.final.html")).to be true
    expect(File.exist?("#{RESULTS}/rice1-en.final.html")).to be true
  end
end
