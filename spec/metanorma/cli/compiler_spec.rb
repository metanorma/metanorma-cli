require "spec_helper"

RSpec.describe Metanorma::Cli::Compiler do
  describe ".compile" do
    it "raises FileNotFoundError for missing file" do
      expect do
        described_class.compile("nonexistent.adoc", {})
      end.to raise_error(
        Metanorma::Cli::Errors::FileNotFoundError,
        /does not exist/,
      )
    end

    it "raises FileNotFoundError for a directory" do
      expect do
        described_class.compile(Dir.tmpdir, {})
      end.to raise_error(
        Metanorma::Cli::Errors::FileNotFoundError,
        /not a file/,
      )
    end

    it "compiles a document and writes output files" do
      Dir.mktmpdir("rspec-") do |dir|
        described_class.compile(
          sample_asciidoc_file,
          output_dir: dir,
          continue_without_fonts: true,
        )

        expect(File.exist?("#{dir}/sample-file.html")).to be true
        expect(File.exist?("#{dir}/sample-file.xml")).to be true
        expect(File.exist?("#{dir}/sample-file.presentation.xml")).to be true
      end
    end
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||= Metanorma::Cli.root_path.join(
      "spec",
      "fixtures",
      "sample-file.adoc",
    ).to_s
  end
end
