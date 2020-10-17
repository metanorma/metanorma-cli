require "spec_helper"

RSpec.describe Metanorma::Cli::SiteGenerator do
  describe ".generate" do
    it "geneates the mini site from collection" do
      source_path = Metanorma::Cli.root_path.join("tmp")

      Metanorma::Cli::SiteGenerator.generate(source_path)
    end
  end
end
