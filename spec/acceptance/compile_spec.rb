require "spec_helper"

RSpec.describe "Metanorma" do
  describe "compile" do
    it "compile a document to desire document type" do
      command = %W(compile -t iso #{sample_asciidoc_file})
      allow(Metanorma::Cli::Compiler).to receive(:compile).and_return []

      capture_stdout { Metanorma::Cli.start(command) }
      registered_tags = Metanorma::Registry.instance.root_tags

      expect(registered_tags[:ogc]).to eq("ogc-standard")
      expect(Metanorma::Cli::Compiler,).to have_received(:compile).
        with(sample_asciidoc_file, "format" => :asciidoc, "type" => "iso")
    end
  end

  describe "failure" do
    it "returns the correct status code" do
      begin
        command = %w(compile -t iso invalid-file)
        capture_stdout { Metanorma::Cli.start(command) }

      rescue SystemExit => error
        expect(error.status).to eq(Errno::ENOENT::Errno)
      end
    end
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||=
      Metanorma::Cli.root_path.
      join("spec", "fixtures", "sample-file.adoc").to_s
  end
end
