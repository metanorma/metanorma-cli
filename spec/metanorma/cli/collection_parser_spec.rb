require "spec_helper"

RSpec.describe Metanorma::Cli::CollectionParser do
  describe ".parse" do
    it "parse the options properly" do

      Metanorma::Cli::CollectionParser.parse(sample_collection_file)
    end
  end

  def sample_collection_file
    @sample_collection_file ||= Metanorma::Cli.root_path.join(
      "collection_with_options.yml"
    )
  end
end
