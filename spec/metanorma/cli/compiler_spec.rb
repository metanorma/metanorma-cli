require "spec_helper"

RSpec.describe Metanorma::Cli::Compiler do
  describe ".compile" do
    it "compile a document to desire formats" do
      compiler = double("Metanorma::Compile", compile: nil, errors: [])
      allow(Metanorma::Compile).to receive(:new).and_return(compiler)

      Metanorma::Cli::Compiler.compile(sample_asciidoc_file, attributes)

      expect(compiler).to have_received(:compile).with(
        sample_asciidoc_file, attributes
      )
    end

    it "compile with errors" do
      expect do
        Metanorma::Cli.start(["spec/fixtures/draft-gold-acvp-sub-kdf135-x942.adoc"])
      end.to raise_error SystemExit
      File.delete "spec/fixtures/draft-gold-acvp-sub-kdf135-x942.err"
      File.delete "spec/fixtures/draft-gold-acvp-sub-kdf135-x942.rfc.xml"
    end
  end

  def attributes
    {
      type: "iso",
      extract_type: [],
      extension_keys: [],
    }
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||=
      Metanorma::Cli.root_path.
      join("spec", "fixtures", "sample-file.adoc").to_s
  end
end
