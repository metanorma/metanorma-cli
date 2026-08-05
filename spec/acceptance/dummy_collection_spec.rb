require "fileutils"
require "tmpdir"

RSpec.describe "Dummy ISO 10303 Collection" do
  around(:each) do |example|
    Dir.mktmpdir("rspec-dummy-collection-") do |temp_directory|
      FileUtils.cp_r("spec/fixtures/dummy_collection/.", temp_directory)
      Dir.chdir(temp_directory) { example.run }
    end
  end

  it "renders the collection via metanorma site generate" do
    capture_stdout do
      Metanorma::Cli.start(%w[site generate --no-install-fonts])
    end
    expect(File.directory?("_site")).to be_truthy
    expect(File.exist?("_site/index.html")).to be_truthy
  end
end
