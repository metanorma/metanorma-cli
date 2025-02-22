require "spec_helper"

RSpec.describe "Metanorma" do
  describe "compile" do
    it "compile a document to desire document type" do
      command = %W(compile -t iso #{sample_asciidoc_file})
      allow(Metanorma::Cli::Compiler).to receive(:compile).and_return []

      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .with(
          sample_asciidoc_file,
          format: :asciidoc,
          type: "iso",
          progress: false,
          install_fonts: true,
        )
    end

    it "supports wildcard document selection" do
      sample_file_with_wildcard = fixtures_path.join("*.adoc")
      allow(Metanorma::Cli::Compiler).to receive(:compile).and_return([])

      command = %W(compile -t iso #{sample_file_with_wildcard})
      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::Compiler).to have_received(:compile).thrice
      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .with(
          sample_asciidoc_file,
          format: :asciidoc,
          type: "iso",
          progress: false,
          install_fonts: true,
        )
    end
  end

  describe "failure" do
    it "returns the correct status code" do
      command = %w(compile -t iso invalid-file)
      expect { Metanorma::Cli.start(command) }
        .to raise_error(SystemExit) { |e|
          expect(e.status).to eq(Errno::ENOENT::Errno)
        }
    end
  end

  def fixtures_path
    @fixtures_path ||= Metanorma::Cli.root_path.join("spec", "fixtures")
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||= fixtures_path.join("sample-file.adoc").to_s
  end
end
