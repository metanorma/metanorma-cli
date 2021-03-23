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
        with(sample_asciidoc_file, format: :asciidoc, type: "iso", no_progress: true)
    end

    it "supports wildcard document selection" do
      sample_file_with_wildcard = fixtures_path.join("*.adoc")
      allow(Metanorma::Cli::Compiler).to receive(:compile).and_return([])

      command = %W(compile -t iso #{sample_file_with_wildcard})
      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::Compiler).to have_received(:compile).thrice
      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .with(sample_asciidoc_file, format: :asciidoc, type: "iso", no_progress: true)
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

    it "returns with 1 status when metanorma can't handle compilation" do
      begin
        capture_stdout {
          Metanorma::Cli.start(
            %W(compile #{fixtures_path.join("mn-samples-ietf-antioch.adoc")})
          )
        }

      rescue SystemExit => error
        expect(error.status).to eq(1)
      end
    end
  end

  def fixtures_path
    @fixtures_path ||= Metanorma::Cli.root_path.join("spec", "fixtures")
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||= fixtures_path.join("sample-file.adoc").to_s
  end
end
