require "spec_helper"

RSpec.describe "Metanorma" do
  describe "diff" do
    let(:fixtures) { File.join(Dir.pwd, "spec", "fixtures", "diff") }

    it "prints Equivalent and exits zero for equivalent documents" do
      output = capture_stdout do
        Metanorma::Cli.start(
          ["diff", File.join(fixtures, "base.xml"),
           File.join(fixtures, "cosmetic.xml")],
        )
      end
      expect(output).to include("Equivalent")
    end

    it "exits non-zero for semantically different documents" do
      expect do
        capture_stdout do
          Metanorma::Cli.start(
            ["diff", File.join(fixtures, "base.xml"),
             File.join(fixtures, "changed.xml"), "--no-color"],
          )
        end
      end.to raise_error(SystemExit) { |e| expect(e.status).to eq 1 }
    end
  end
end
