require "spec_helper"

RSpec.describe "Metanorma" do
  describe "list-extensions" do
    it "lists available extensions for a type" do
      command = %w(list-extensions iso)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Supported extensions: xml, presentation, rxl, html")
    end

    it "lists all extensions if no type specified" do
      command = %w(list-extensions)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("iso: xml, presentation, rxl, html")
      expect(output).to include("csa: xml, presentation, rxl, html, doc and pdf")
      expect(output).to include("ietf: rxl, xml, rfc, html, txt and pdf")
    end

    it "gracefully handles invalid types" do
      command = %w(list-extensions iso-invalid)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Couldn't load iso-invalid, please provide")
    end
  end
end
