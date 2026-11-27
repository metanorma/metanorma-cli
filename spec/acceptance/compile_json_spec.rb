require "spec_helper"
require "json"
require "tmpdir"

RSpec.describe "Metanorma" do
  describe "compile -x json" do
    before { skip_without_json_iso }

    let(:adoc) do
      <<~ADOC
        = Sample Title
        :docnumber: 1000
        :doctype: international-standard
        :no-isobib:

        == Scope

        Hello world.

        [bibliography]
        == Normative references

        Some reference text.
      ADOC
    end

    # A failed compile exits the process (SystemExit), which fails the example.
    let(:doc) do
      Dir.mktmpdir("rspec-json-") do |dir|
        source = File.join(dir, "sample.adoc")
        File.write(source, adoc)

        capture_stdout do
          Metanorma::Cli.start(["compile", "-t", "iso", "-x", "json",
                                "--no-install-fonts", "-o", dir, source])
        end

        JSON.parse(File.read(File.join(dir, "sample.json")))
      end
    end

    # Skips (not passes) when the installed metanorma has no json format.
    def skip_without_json_iso
      Metanorma::Cli.load_flavors
      processor = Metanorma::Registry.instance.processors[:iso]
      return if processor&.output_formats&.key?(:json)

      skip "installed metanorma has no json output format for iso"
    end

    def clause_titles(node)
      return [] unless node.is_a?(Hash)

      own = node["type"] == "clause" ? [node.dig("attrs", "title")] : []
      own + Array(node["content"]).flat_map { |c| clause_titles(c) }
    end

    it "emits the document model with the iso flavor" do
      expect(doc["attrs"]).to include("flavor" => "iso")
    end

    it "keeps the clause titles in the emitted model" do
      expect(clause_titles(doc)).to include("Scope")
    end
  end
end
