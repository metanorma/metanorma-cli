require "spec_helper"

RSpec.describe "Metanorma" do
  describe "compile" do
    it "compiles a document to the specified type" do
      Dir.mktmpdir("rspec-") do |dir|
        command = %W(compile -t iso -o #{dir} --no-install-fonts
                     #{sample_asciidoc_file})

        capture_stdout { Metanorma::Cli.start(command) }

        expect(Dir.glob(File.join(dir, "*")).length).to be > 0
      end
    end
  end

  describe "failure" do
    it "exits with error for invalid file" do
      command = %w(compile -t iso invalid-file)
      expect { Metanorma::Cli.start(command) }.to raise_error(SystemExit)
    end
  end

  def fixtures_path
    @fixtures_path ||= Metanorma::Cli.root_path.join("spec", "fixtures")
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||= fixtures_path.join("sample-file.adoc").to_s
  end
end
