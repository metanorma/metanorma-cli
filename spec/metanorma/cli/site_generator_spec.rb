require "spec_helper"

RSpec.describe Metanorma::Cli::SiteGenerator do
  describe ".generate" do
    context "without  manifest file" do
      it "invokes sets of messages to generate a complete site" do
        asset_folder = "documents"
        stub_external_interface_calls

        Metanorma::Cli::SiteGenerator.generate(
          source_path, output_dir: output_directory
        )

        expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
          sources.first.to_s, format: :asciidoc, "output-dir" => asset_folder
        )

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder, "documents.xml", title: "", organization: ""
        )
      end

      it "converts the collection xml to html and reanmes it to index" do
        stub_external_interface_calls
        collection_xml = "documents.xml"

        Metanorma::Cli::SiteGenerator.generate(
          source_path, output_dir: output_directory
        )

        expect(File).to have_received(:rename).with(
          Pathname.new(collection_xml).sub_ext(".html").to_s, "index.html"
        )

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
          collection_xml,
        )
      end
    end

    context "with manifest file" do
      it "usages the manifest to select files and passes it to relaton" do
        asset_folder = "documents"
        stub_external_interface_calls

        Metanorma::Cli::SiteGenerator.generate(
          source_path.join("invalid"),
          output_dir: output_directory,
          config: source_path.join("metanorma.yml"),
        )

        collection = manifest["relaton"]["collection"]
        manifest_files = manifest["metanorma"]["source"]["files"]

        manifest_files.each do |manifest_file|
          expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
            source_path.join(manifest_file).to_s,
            format: :asciidoc,
            "output-dir" => asset_folder,
          )
        end

        expect(Metanorma::Cli::Compiler).to have_received(:compile).twice

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder,
          "documents.xml",
          title: collection["name"],
          organization: collection["organization"],
        )
      end
    end

    def stub_external_interface_calls
      allow(File).to receive(:rename)
      allow(Metanorma::Cli::Compiler).to receive(:compile)
      allow(Relaton::Cli::XMLConvertor).to receive(:to_html)
      allow(Relaton::Cli::RelatonFile).to receive(:concatenate)
    end

    def sources
      @sources ||= Dir[File.join(source_path.to_s, "**", "*.adoc")]
    end

    def output_directory
      @output_directory ||= Metanorma::Cli.root_path.join("tmp")
    end

    def source_path
      @source_path ||= Metanorma::Cli.root_path.join("spec", "fixtures")
    end

    def manifest
      @manifest ||= YAML.safe_load(File.read(source_path.join("metanorma.yml")))
    end
  end
end
