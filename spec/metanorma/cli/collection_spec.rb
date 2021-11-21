require "spec_helper"

RSpec.describe Metanorma::Cli::Collection do
  describe ".render" do
    context "with specified options" do
      it "compiles and renders the collection files" do
        allow(Metanorma::Collection).to receive_message_chain(:parse, :render)
        Metanorma::Cli::Collection.render(collection_file, format: "html")
      end
    end
  end

  def collection_file
    @collection_file ||= Metanorma::Cli.root_path.join(
      "spec", "fixtures", "collection1.yml"
    )
  end
end
