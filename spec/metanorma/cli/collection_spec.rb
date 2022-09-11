require "spec_helper"

RSpec.describe Metanorma::Cli::Collection do
  describe ".render" do
    context "with specified options" do
      it "compiles and renders the collection files" do
        collection = mock_collection_instance

        Metanorma::Cli::Collection.render(
          collection_file,
          format: "html, pdf",
          output_folder: "bilingual-brochure",
        )

        expect(collection).to have_received(:render).with(
          format: %I(html pdf), output_folder: "bilingual-brochure",
        )
      end
    end

    context "with embedded options" do
      it "extracts options from file and renders collection" do
        collection = mock_collection_instance

        collection_file = collection_file("collection_with_options.yml")
        Metanorma::Cli::Collection.render(collection_file)

        expect(collection).to have_received(:render).with(
          coverpage: "collection_cover.html",
          output_folder: "bilingual-brochure",
          format: %I(xml html presentation pdf),
        )
      end
    end

    context "with missing options" do
      it "usages the source as reference for options" do
        collection = mock_collection_instance

        Metanorma::Cli::Collection.render(collection_file)

        expect(collection).to have_received(:render).with(
          hash_including(output_folder: File.dirname(collection_file.to_s)),
        )
      end
    end
  end

  def collection_file(collection = "collection1.yml")
    Metanorma::Cli.root_path.join("spec", "fixtures", collection)
  end

  def mock_collection_instance
    collection = double(Metanorma::Collection, parse: nil, render: nil)
    allow(Metanorma::Collection).to receive(:parse).and_return(collection)

    collection
  end
end
