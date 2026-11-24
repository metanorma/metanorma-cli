require "spec_helper"
require "json"
require "tmpdir"

RSpec.describe "Metanorma" do
  describe "compile -x json" do
    let(:adoc) do
      <<~ADOC
        = Sample Title
        :docnumber: 1000
        :doctype: international-standard
        :no-isobib:

        == Scope

        Hello world.

        == Normative references

        Some reference text.
      ADOC
    end

    def clause_titles(node)
      return [] unless node.is_a?(Hash)

      own = node["type"] == "clause" ? [node.dig("attrs", "title")] : []
      own + Array(node["content"]).flat_map { |c| clause_titles(c) }
    end

    it "emits the document model as valid Metanorma JSON" do
      Dir.mktmpdir("rspec-json-") do |dir|
        source = File.join(dir, "sample.adoc")
        File.write(source, adoc)

        capture_stdout do
          Metanorma::Cli.start(["compile", "-t", "iso", "-x", "json",
                                "--no-install-fonts", "-o", dir, source])
        end

        doc = JSON.parse(File.read(File.join(dir, "sample.json")))
        expect(doc["attrs"]).to include("flavor" => "iso")
        expect(clause_titles(doc)).to include("Scope")
      end
    end
  end
end
