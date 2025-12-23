require "spec_helper"

RSpec.describe "Metanorma" do
  describe "list-doctypes" do
    context "without any type specified" do
      it "list details for supported doctypes" do
        command = %w(list-doctypes)
        output = capture_stdout { Metanorma::Cli.start(command) }
        output.gsub!(/\s+/, " ")

        expect(output).to include("Type Input Supported output format")
        expect(output).to include("standoc asciidoc xml, presentation, rxl")
        expect(output).to include("icc asciidoc xml, html, pdf, doc and presentation")
      end
    end

    context "with type specified" do
      it "list out the details for that type" do
        command = %w(list-doctypes iso)
        output = capture_stdout { Metanorma::Cli.start(command) }
        output.gsub!(/\s+/, " ")
        warn output

        expect(output).to include("Type Input Supported output format")
        expect(output).to include("iso asciidoc xml, presentation, rxl, html")
        expect(output).not_to include("icc asciidoc xml, html, pdf, doc and presentation")

        command = %w(list-doctypes icc)
        output = capture_stdout { Metanorma::Cli.start(command) }
        output.gsub!(/\s+/, " ")

        expect(output).to include("Type Input Supported output format")
        expect(output).not_to include("iso asciidoc xml, presentation, rxl, html")
        expect(output).to include("icc asciidoc xml, html, pdf, doc and presentation")
      end
    end
  end
end
