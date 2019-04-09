require "spec_helper"

RSpec.describe Metanorma::Cli::Compiler do
  describe ".compile" do
    it "compile a document to desire formats" do
      compiler = double("Metanorma::Compile", compile: nil)
      allow(Metanorma::Compile).to receive(:new).and_return(compiler)

      Metanorma::Cli::Compiler.compile(sample_asciidoc_file, attributes)

      expect(compiler).to have_received(:compile).with(
        sample_asciidoc_file, attributes
      )
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
