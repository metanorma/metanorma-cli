require "spec_helper"
require "json"
require "tmpdir"

RSpec.describe "Metanorma" do
  describe "compile -x json" do
    before { skip_without_json_format }

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

    let(:doc) do
      Dir.mktmpdir("rspec-json-src-") do |dir|
        source = File.join(dir, "sample.adoc")
        File.write(source, adoc)
        compile_json("iso", source)
      end
    end

    # Skips (not passes) when the installed metanorma has no json output format.
    def skip_without_json_format
      return if Metanorma::Compile::CompileOptions::HARNESS_OUTPUT_FORMATS.key?(:json)

      skip "installed metanorma has no json output format"
    end

    # A failed compile exits the process (SystemExit), which fails the example.
    def compile_json(type, source)
      Dir.mktmpdir("rspec-json-out-") do |out|
        capture_stdout do
          Metanorma::Cli.start(["compile", "-t", type, "-x", "json",
                                "--no-install-fonts", "-o", out, source])
        end

        json = File.join(out, "#{File.basename(source, '.adoc')}.json")
        JSON.parse(File.read(json))
      end
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

    {
      "sample-file.adoc" => "iso",
      "sample-itu.adoc" => "itu",
    }.each do |name, type|
      it "emits a valid JSON document model for #{name}" do
        model = with_fixture_in_tmpdir(name) { compile_json(type, name) }

        expect(model).to include("type" => "doc",
                                 "attrs" => include("flavor" => type),
                                 "content" => be_an(Array))
      end
    end
  end
end
