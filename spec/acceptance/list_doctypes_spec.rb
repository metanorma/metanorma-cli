require "spec_helper"

RSpec.describe "Metanorma" do
  describe "list-doctypes" do
    context "without any type specified" do
      it "list details for supported doctypes" do
        command = %w(list-doctypes)
        output = capture_stdout { Metanorma::Cli.start(command) }

        expect(output).to include("Type     Input     Supported output format")
        expect(output).to include("standoc  asciidoc  xml, presentation, rxl")
      end
    end

    context "with type specified" do
      it "list out the details for that type" do
        command = %w(list-doctypes iso)
        output = capture_stdout { Metanorma::Cli.start(command) }

        expect(output).to include("Type  Input     Supported output format")
        expect(output).to include("iso   asciidoc  xml, presentation, rxl, html")
      end
    end
  end
end
