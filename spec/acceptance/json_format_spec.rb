require "spec_helper"

RSpec.describe "Metanorma" do
  describe "json output format" do
    it "documents `-x json` in compile help" do
      output = capture_stdout { Metanorma::Cli.start(%w(help compile)) }

      expect(output).to include("metanorma compile -t iso -x json")
    end

    context "when the registry exposes a json output format" do
      let(:processor) do
        Struct.new(:input_format, :output_formats)
          .new(:asciidoc, { xml: "xml", json: "json" })
      end

      before do
        allow(Metanorma::Registry.instance).to receive(:processors)
          .and_return(iso: processor)
      end

      it "lists json in the format table, read from the registry" do
        output = capture_stdout { Metanorma::Cli.start(%w(list-doctypes iso)) }
        output.gsub!(/\s+/, " ")

        expect(output).to include("iso asciidoc xml and json")
      end
    end
  end
end
