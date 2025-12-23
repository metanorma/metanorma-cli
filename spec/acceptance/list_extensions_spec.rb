require "spec_helper"

RSpec.describe "Metanorma" do
  describe "list-extensions" do
    it "lists available extensions for a type" do
      command = %w(list-extensions iso)
      output = capture_stdout { Metanorma::Cli.start(command) }
      expect(output).to include("Supported extensions: xml, presentation, rxl, html")

      command = %w(list-extensions icc)
      output = capture_stdout { Metanorma::Cli.start(command) }
      expect(output).to include("Supported extensions: xml, html, pdf, doc and presentation")
    end

    it "lists all extensions if no type specified" do
      command = %w(list-extensions)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("iso: xml, presentation, rxl, html")
      expect(output).to include("cc: html, doc, xml, presentation, rxl and pdf")
      expect(output).to include("ietf: rxl, xml, rfc, html, txt and pdf")
      expect(output).to include("icc: xml, html, pdf, doc and presentation")
    end

    it "gracefully handles invalid types" do
      command = %w(list-extensions iso-invalid)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Couldn't load iso-invalid, please provide")
    end
  end
end
