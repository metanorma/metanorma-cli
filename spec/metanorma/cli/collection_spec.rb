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
          format: %I(html pdf),
          output_folder: Pathname.new("bilingual-brochure"),
        )
      end
    end

    context "with embedded options" do
      it "extracts options from file and renders collection" do
        root_path = Metanorma::Cli.root_path
        collection = mock_collection_instance
        collection_file = collection_file("collection_with_options.yml")

        Metanorma::Cli::Collection.render(
          collection_file,
          output_dir: root_path,
        )

        expect(collection).to have_received(:render).with(
          coverpage: "collection_cover.html",
          format: %I(xml html presentation pdf),
          output_folder: root_path.join("bilingual-brochure"),
        )
      end
    end

    context "with missing options" do
      it "usages the source as reference for options" do
        collection = mock_collection_instance

        Metanorma::Cli::Collection.render(collection_file)

        expect(collection).to have_received(:render).with(
          hash_including(output_folder: collection_file.dirname),
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
