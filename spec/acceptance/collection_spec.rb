RESULTS = "spec/results".freeze

RSpec.describe "Collection" do
  describe "collection" do
    it "render HTML from YAML" do
      require "debug"; binding.b
      run_metanorma_collection("collection1.yml")
      expect_generated_files_to_match_expectations
    end

    it "Render HTML from XML" do
      run_metanorma_collection("collection1.xml")
      expect_generated_files_to_match_expectations
    end
  end

  around(:each) do |example|
    Dir.mktmpdir("rspec-") do |temp_directory|
      FileUtils.cp(Dir.glob("spec/fixtures/*"), temp_directory)
      Dir.chdir(temp_directory) { example.run }
    end
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
    %w(index.html rice-amd.final.html rice-en.final.html rice1-en.final.html)
  end
end
