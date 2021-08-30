require "spec_helper"

RSpec.describe Metanorma::Cli::SiteGenerator do
  describe ".generate" do
    context "without manifest file" do
      it "detects input documents and generate a complete site" do
        asset_folder = "documents"
        stub_external_interface_calls
        asset_directory = output_directory.join(asset_folder)

        Metanorma::Cli::SiteGenerator.generate(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: false,
        )

        expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
          sources.first.to_s,
          format: :asciidoc,
          output_dir: asset_directory,
          continue_without_fonts: false,
        )

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder, "documents.xml", title: "", organization: ""
        )
      end

      it "pass --no-progress option to compiler" do
        asset_folder = "documents"
        stub_external_interface_calls
        asset_directory = output_directory.join(asset_folder)

        Metanorma::Cli::SiteGenerator.generate(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: false,
          no_progress: false,
        )

        expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
          sources.first.to_s,
          format: :asciidoc,
          output_dir: asset_directory,
          continue_without_fonts: false,
          no_progress: false,
        )

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder, "documents.xml", title: "", organization: ""
        )
      end

      it "converts collection xml to html and renames it to index" do
        stub_external_interface_calls
        collection_xml = "documents.xml"

        Metanorma::Cli::SiteGenerator.generate(
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
        asset_folder = "documents"
        stub_external_interface_calls

        Metanorma::Cli::SiteGenerator.generate(
          source_path,
          { output_dir: output_directory,
            config: source_path.join("metanorma.yml") },
          continue_without_fonts: false,
        )

        collection = manifest["metanorma"]["collection"]
        manifest_files = select_files_including_wildcard(
          manifest["metanorma"]["source"]["files"],
        )

        manifest_files.each do |manifest_file|
          expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
            source_path.join(manifest_file).to_s,
            format: :asciidoc,
            output_dir: output_directory.join(asset_folder),
            continue_without_fonts: false,
          )
        end

        expect(Metanorma::Cli::Compiler).to have_received(:compile).exactly(
          manifest_files.uniq.count,
        ).times

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          asset_folder,
          "documents.xml",
          title: collection["name"],
          organization: collection["organization"],
        )
      end
    end

    context "custom site template" do
      it "respects template options and pass it down to relaton" do
        stub_external_interface_calls

        template_dir = "template-dir-as-option"
        stylesheet_path = "stylesheet-as-option"

        Metanorma::Cli::SiteGenerator.generate(
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
        stub_external_interface_calls

        Metanorma::Cli::SiteGenerator.generate(
          source_path,
          output_dir: output_directory,
          config: source_path.join("metanorma.yml"),
        )

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
          "documents.xml",
          manifest["metanorma"]["template"]["stylesheet"],
          manifest["metanorma"]["template"]["path"],
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
      @output_directory ||= @tmp_dir
    end

    def select_files_including_wildcard(files)
      files.map do |file|
        file_path = source_path.join(file).to_s
        file_path.to_s.include?("*") ? Dir.glob(file_path) : file_path
      end.flatten
    end

    def source_path
      @source_path ||= Metanorma::Cli.root_path.join("spec", "fixtures")
    end

    def manifest
      @manifest ||= YAML.safe_load(File.read(source_path.join("metanorma.yml")))
    end
  end
end
