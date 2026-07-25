require "spec_helper"

RSpec.describe Metanorma::Cli::ConfigExporter do
  describe "#export" do
    context "without a type" do
      it "outputs a message to specify a type" do
        exporter = described_class.new(nil)
        output = capture_stdout { exporter.export }
        expect(output).to include("Please specify a standard type")
      end
    end
  end
end
