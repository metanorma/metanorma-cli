require "spec_helper"

RSpec.describe "Metanorma" do
  describe "list-extensions" do
    it "lists available extensions for a type" do
      command = %w(list-extensions iso)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Supported extensions: xml, rxl, html")
    end

    it "gracefully handles invalid types" do
      command = %w(list-extensions iso-invalid)
      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Couldn't load iso-invalid, please provide")
    end
  end
end
