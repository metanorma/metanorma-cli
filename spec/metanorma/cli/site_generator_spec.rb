require "spec_helper"

RSpec.describe Metanorma::Cli::SiteGenerator do
  describe ".generate!" do
    def select_files_including_wildcard(files)
      result = files.map do |file|
        file_path = source_path.join(file).to_s
        file_path.to_s.include?("*") ? Dir.glob(file_path) : file_path
      end
      result.flatten!
      result.uniq!
      result
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
      tmp_dir.realpath
    end

    let(:asset_directory) do
      output_directory.join(asset_folder).realpath
    end

    let(:source_path) do
      Metanorma::Cli.root_path.join("spec", "fixtures")
    end

    let(:manifest_file_path) do
      source_path.join("metanorma.yml")
    end

    let(:manifest_yaml) do
      File.read(manifest_file_path)
    end

    let(:manifest) do
      Metanorma::SiteManifest::Base.from_yaml(manifest_yaml)
    end

    let(:sub_manifest_files) do
      select_files_including_wildcard(
        manifest.metanorma.source.files,
      ).reject { |file| file.to_s.include?("yml") }
    end

    let(:collection_xml_path) do
      "documents.xml"
    end

    context "without manifest file" do
      it "detects input documents and generate a complete site" do
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
          output_filename_template: nil,
          continue_without_fonts: false,
          site_generate: true,
        )

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          ".", collection_xml_path, title: "", organization: ""
        )
      end

      it "passes --output-filename-template option to compiler" do
        output_filename_template = "output_filename_template"
        described_class.generate!(
          source_path,
          { output_dir: output_directory,
            output_filename_template: output_filename_template },
          continue_without_fonts: false,
        )

        expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
          sources.first.to_s,
          baseassetpath: source_path.to_s,
          format: :asciidoc,
          output_dir: asset_directory,
          output_filename_template: output_filename_template,
          continue_without_fonts: false,
          site_generate: true,
        )
      end

      it "pass --no-progress option to compiler" do
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
          output_filename_template: nil,
          continue_without_fonts: false,
          progress: false,
          site_generate: true,
        )

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          ".", collection_xml_path, title: "", organization: ""
        )
      end

      it "converts collection xml to html and renames it to index" do
        described_class.generate!(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: false,
        )

        expect(File).to have_received(:rename).with(
          Pathname.new(collection_xml_path).sub_ext(".html").to_s, "index.html"
        )

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
          collection_xml_path, nil, nil
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

        sub_manifest_files.each do |manifest_file|
          expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
            source_path.join(manifest_file).to_s,
            baseassetpath: source_path.to_s,
            format: :asciidoc,
            output_dir: output_directory.join(asset_folder),
            output_filename_template:
              "your-filename-template-{{ document.docidentifier }}",
            continue_without_fonts: false,
            site_generate: true,
          )
        end

        expect(Metanorma::Cli::Compiler).to have_received(:compile).exactly(
          sub_manifest_files.uniq.count,
        ).times

        expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).with(
          ".",
          collection_xml_path,
          title: collection.name,
          organization: collection.organization,
        )
      end

      context "with manifest specifying template.output_filename" do
        let(:template_output_filename) { "{{ document.title }}" }
        let(:collection_name) { "My Collection" }
        let(:collection_org) { "My Organization" }
        let(:template_stylesheet) { "stylesheet.css" }
        let(:template_path) { "path/to/template" }

        let(:expected_base_path) { source_path.realpath }
        let(:expected_stylesheet_path) do
          expected_base_path.join(template_stylesheet)
        end
        let(:expected_template_path) do
          expected_base_path.join(template_path)
        end

        let(:manifest_yaml) { <<~YAML }
          metanorma:
            source:
              files:
                - "*.adoc"
            collection:
              name: #{collection_name.inspect}
              organization: #{collection_org.inspect}
            template:
              stylesheet: #{template_stylesheet.inspect}
              output_filename: #{template_output_filename.inspect}
              path: #{template_path.inspect}
        YAML

        it "handles output_filename_template from manifest" do
          allow(File).to receive(:read)
            .with(manifest_file_path.to_s)
            .and_return(manifest_yaml)
          described_class.generate!(
            source_path,
            { output_dir: output_directory,
              config: manifest_file_path },
            continue_without_fonts: false,
          )

          sub_manifest_files.each do |manifest_file|
            expect(Metanorma::Cli::Compiler).to have_received(:compile).with(
              source_path.join(manifest_file).to_s,
              baseassetpath: source_path.to_s,
              format: :asciidoc,
              output_dir: output_directory.join(asset_folder),
              output_filename_template: template_output_filename,
              continue_without_fonts: false,
              site_generate: true,
            )

            expect(Relaton::Cli::RelatonFile)
              .to have_received(:concatenate)
              .with(".",
                    collection_xml_path,
                    title: collection_name,
                    organization: collection_org)

            expect(File).to have_received(:rename).with(
              Pathname.new(collection_xml_path)
                .sub_ext(".html").to_s,
              "index.html",
            )

            expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
              collection_xml_path,
              expected_stylesheet_path,
              expected_template_path,
            )
          end
        end
      end

      it "handles collection generation properly" do
        allow(Metanorma::Cli::Collection).to receive(:render)

        described_class.generate!(
          source_path,
          {
            output_dir: output_directory,
            config: source_path.join("metanorma.yml"),
            site_generate: true,
          },
          continue_without_fonts: false,
        )

        [
          "collection_with_options.yml",
          "collection_with_options2.yml",
        ].map do |file|
          expect(Metanorma::Cli::Collection).to have_received(:render).with(
            source_path.join(file).to_s,
            output_dir: asset_directory,
            compile: { continue_without_fonts: false },
            site_generate: true,
          )
        end
      end
    end

    context "custom site template" do
      context "without manifest file" do
        let(:expected_base_path) { Pathname.pwd }
        let(:expected_stylesheet_path) do
          expected_base_path.join(stylesheet_path)
        end
        let(:expected_template_path) do
          expected_base_path.join(template_dir)
        end

        let(:stylesheet_path) { "stylesheet-as-option" }
        let(:template_dir) { "template-dir-as-option" }

        it "respects template options and pass it down to relaton" do
          described_class.generate!(
            source_path,
            output_dir: output_directory,
            template_dir: template_dir,
            stylesheet: stylesheet_path,
          )

          expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
            collection_xml_path,
            expected_stylesheet_path,
            expected_template_path,
          )
        end
      end

      context "with manifest file" do
        let(:expected_base_path) { source_path.realpath }
        let(:expected_stylesheet_path) do
          expected_base_path.join(manifest.metanorma.template.stylesheet)
        end
        let(:expected_template_path) do
          expected_base_path.join(manifest.metanorma.template.path)
        end

        it "uses its template configuration" do
          described_class.generate!(
            source_path,
            output_dir: output_directory,
            config: source_path.join("metanorma.yml"),
          )

          expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).with(
            collection_xml_path,
            expected_stylesheet_path,
            expected_template_path,
          )
        end
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

    context "with XML collection files" do
      it "includes XML files in collection files" do
        # Create a temporary XML file in the source directory
        xml_file = source_path.join("test_collection.xml")
        File.write(xml_file, "<test>XML content</test>")

        # Create a SiteGenerator instance
        generator = described_class.new(source_path,
                                        { output_dir: output_directory })

        # Call the method that selects collection files
        collection_files = generator.send(:select_source_collection_files)

        # Verify that the XML file is included
        expect(collection_files.map(&:to_s)).to include(xml_file.to_s)

        # Clean up
        File.delete(xml_file)
      end

      it "processes XML collection files during site generation" do
        # Create a temporary XML file in the source directory
        xml_file = source_path.join("test_collection.xml")
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(xml_file.to_s)
          .and_return("<test>XML content</test>")

        # Modify manifest to include the XML file
        manifest_yaml = <<~YAML
          metanorma:
            source:
              files:
                - test_collection.xml
            collection:
              name: My Collection
              organization: My Organization
            template:
              stylesheet: stylesheet.css
              output_filename: output_filename_template
              template_dir: template_dir
        YAML

        allow(File).to receive(:read).with(manifest_file_path.to_s)
          .and_return(manifest_yaml)

        # Create RSpec spy
        allow(Metanorma::Cli::Collection).to receive(:render)

        # Generate the site
        described_class.generate!(
          source_path,
          {
            output_dir: output_directory,
            config: manifest_file_path,
          },
          continue_without_fonts: false,
        )

        # Verify that Collection.render was called with the XML file
        expect(Metanorma::Cli::Collection).to have_received(:render).with(
          xml_file.to_s,
          compile: { continue_without_fonts: false },
          output_dir: asset_directory,
          site_generate: true,
        )
      end

      it "recognizes XML files as collection files" do
        # Create a temporary XML file
        xml_file = Pathname.new("test.xml")

        # Create a SiteGenerator instance
        generator = described_class.new(source_path,
                                        { output_dir: output_directory })

        # Call the collection_file? method
        result = generator.send(:collection_file?, xml_file)

        # Verify that XML files are recognized as collection files
        expect(result).to be true
      end
    end
  end
end
