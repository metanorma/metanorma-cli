require "spec_helper"

RSpec.describe "Metanorma" do
  describe "compile" do
    it "compile a document to desire document type" do
      command = %W(compile -t iso #{sample_asciidoc_file})
      allow(Metanorma::Cli::Compiler).to receive(:compile)

      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::Compiler,).to have_received(:compile).with(
        sample_asciidoc_file,
        "asciimath" => true,
        "datauriimage" => true,
        "extensions"=> "xml,html",
        "format" => :asciidoc,
        "type" => "iso",
        "wrapper" => true,
      )
    end
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||=
      Metanorma::Cli.root_path.
      join("spec", "fixtures", "sample-file.adoc").to_s
  end
end
