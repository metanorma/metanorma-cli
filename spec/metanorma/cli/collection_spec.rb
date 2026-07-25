require "spec_helper"

RSpec.describe Metanorma::Cli::Collection do
  describe ".parse_formats" do
    it "splits comma-separated format string into symbols" do
      expect(described_class.parse_formats("html, pdf")).to eq(%I[html pdf])
    end

    it "handles already-split array" do
      expect(described_class.parse_formats(%w[html pdf])).to eq(%I[html pdf])
    end

    it "strips whitespace" do
      expect(described_class.parse_formats(" html , pdf ")).to eq(%I[html pdf])
    end

    it "returns empty array for nil" do
      expect(described_class.parse_formats(nil)).to eq([])
    end

    it "returns empty array for empty string" do
      expect(described_class.parse_formats("")).to eq([])
    end
  end
end
