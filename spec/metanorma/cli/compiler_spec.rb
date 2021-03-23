require "spec_helper"

RSpec.describe Metanorma::Cli::Compiler do
  describe ".compile" do
    it "compile a document to desire formats" do
      VCR.use_cassette "workgroup_fetch" do
        compiler = double("Metanorma::Compile", compile: nil, errors: [])
        allow(Metanorma::Compile).to receive(:new).and_return(compiler)

        Metanorma::Cli::Compiler.compile(sample_asciidoc_file, attributes)

        expect(compiler).to have_received(:compile).with(
          sample_asciidoc_file, attributes
        )
      end
    end

    it "write files to specified output dir" do
      VCR.use_cassette "workgroup_fetch" do
        Dir.mktmpdir("rspec-") do |dir|
          Metanorma::Cli.start(["spec/fixtures/sample-file.adoc", "-o", dir, "--no-install-fonts"])
          expect(File.exist?("#{dir}/sample-file.html")).to be true
          expect(File.exist?("#{dir}/sample-file.xml")).to be true
          expect(File.exist?("#{dir}/sample-file.presentation.xml")).to be true
        end
      end
    end
  end

  def attributes
    {
      type: "iso",
      extract_type: [],
      extension_keys: [],
      no_install_fonts: true,
      no_progress: true,
    }
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||= Metanorma::Cli.root_path.join("spec", "fixtures", "sample-file.adoc").to_s
  end

  def delete_file_if_exist(filename)
    filepath = Metanorma::Cli.root_path.join("spec", "fixtures", filename).to_s
    File.delete(filepath) if File.exists?(filepath)
  end
end
