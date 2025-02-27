require "spec_helper"

RSpec.describe Metanorma::Cli::SiteGenerator do
  describe ".generate!" do
    def select_files_including_wildcard(files)
      files.map do |file|
        file_path = source_path.join(file).to_s
        file_path.to_s.include?("*") ? Dir.glob(file_path) : file_path
      end.flatten
    end

    before do
      # stub external interface calls
      allow(File).to receive(:rename)
      allow(Metanorma::Cli::Compiler).to receive(:compile)
      allow(Metanorma::Cli::Collection).to receive(:render)
      allow(Relaton::Cli::XMLConvertor).to receive(:to_html)
      allow(Relaton::Cli::RelatonFile).to receive(:concatenate)
    end

    let(:asset_folder) { "documents" }

    let(:sources) do
      Dir[File.join(source_path.to_s, "**", "*.adoc")]
    end

    let(:output_directory) do
      @tmp_dir
    end

    let(:source_path) do
      Metanorma::Cli.root_path.join("spec", "fixtures")
    end

    let(:manifest) do
      Metanorma::SiteManifest.from_yaml(File.read(source_path.join("metanorma.yml")))
    end

    context "without manifest file" do
      it "detects input documents and generate a complete site" do
        asset_directory = output_directory.join(asset_folder)

        described_class.generate!(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: false,
        )

        expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
          sources.first.to_s,
          baseassetpath: source_path.to_s,
          format: :asciidoc,
          output_dir: asset_directory,
          continue_without_fonts: false,
          site_generate: true,
        )

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder, "documents.xml", title: "", organization: ""
        )
      end

      it "pass --no-progress option to compiler" do
        asset_directory = output_directory.join(asset_folder)

        described_class.generate!(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: false,
          progress: false,
        )

        expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
          sources.first.to_s,
          baseassetpath: source_path.to_s,
          format: :asciidoc,
          output_dir: asset_directory,
          continue_without_fonts: false,
          progress: false,
          site_generate: true,
        )

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder, "documents.xml", title: "", organization: ""
        )
      end

      it "converts collection xml to html and renames it to index" do
        collection_xml = "documents.xml"

        described_class.generate!(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: false,
        )

        expect(File).to have_received(:rename).with(
          Pathname.new(collection_xml).sub_ext(".html").to_s, "index.html"
        )

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
          collection_xml, nil, nil
        )
      end
    end

    context "with manifest file" do
      it "uses the manifest to select files" do
        described_class.generate!(
          source_path,
          { output_dir: output_directory,
            config: source_path.join("metanorma.yml") },
          continue_without_fonts: false,
        )

        collection = manifest.metanorma.collection
        manifest_files = select_files_including_wildcard(
          manifest.metanorma.source.files,
        ).reject { |file| file.to_s.include?("yml") }

        manifest_files.each do |manifest_file|
          expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
            source_path.join(manifest_file).to_s,
            baseassetpath: source_path.to_s,
            format: :asciidoc,
            output_dir: output_directory.join(asset_folder),
            continue_without_fonts: false,
            site_generate: true,
          )
        end

        expect(Metanorma::Cli::Compiler).to have_received(:compile).exactly(
          manifest_files.uniq.count,
        ).times

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder,
          "documents.xml",
          title: collection.name,
          organization: collection.organization,
        )
      end

      it "also handles collection generation properly" do
        described_class.generate!(
          source_path,
          {
            output_dir: output_directory,
            config: source_path.join("metanorma.yml"),
          },
          continue_without_fonts: false,
        )

        collection_file = source_path.join("collection_with_options.yml")

        expect(Metanorma::Cli::Collection).to have_received(:render).with(
          collection_file.to_s,
          output_dir: output_directory,
          compile: { continue_without_fonts: false },
        )
      end
    end

    context "custom site template" do
      it "respects template options and pass it down to relaton" do
        template_dir = "template-dir-as-option"
        stylesheet_path = "stylesheet-as-option"

        described_class.generate!(
          source_path,
          output_dir: output_directory,
          template_dir: template_dir,
          stylesheet: stylesheet_path,
        )

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
          "documents.xml", stylesheet_path, template_dir
        )
      end

      it "allows us to use manifest file for template" do
        described_class.generate!(
          source_path,
          output_dir: output_directory,
          config: source_path.join("metanorma.yml"),
        )

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
          "documents.xml",
          manifest.metanorma.template.stylesheet,
          manifest.metanorma.template.path,
        )
      end
    end

    it "raise error on fatal errors" do
      fatals = [
        "Fatal error 1",
        "Fatal error 2",
        "Fatal error 3",
      ]

      allow(Metanorma::Cli::Compiler).to receive(:compile).and_return(fatals)
      expect do
        described_class.generate!(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: false,
        )
      end.to raise_error(Metanorma::Cli::Errors::FatalCompilationError)
    end
  end
end
