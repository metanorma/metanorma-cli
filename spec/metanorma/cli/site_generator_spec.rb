require "spec_helper"

RSpec.describe Metanorma::Cli::SiteGenerator do
  describe ".generate!" do
    let(:asset_folder) { "documents" }

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

    describe "#collection_file?" do
      let(:generator) do
        described_class.new(source_path, { output_dir: tmp_dir })
      end

      it "recognizes YAML files as collection files" do
        expect(generator.collection_file?(Pathname.new("test.yml"))).to be true
      end

      it "recognizes YML files as collection files" do
        expect(generator.collection_file?(Pathname.new("test.yaml"))).to be true
      end

      it "recognizes XML files as collection files" do
        expect(generator.collection_file?(Pathname.new("test.xml"))).to be true
      end

      it "does not recognize adoc files as collection files" do
        path = Pathname.new("test.adoc")
        expect(generator.collection_file?(path)).to be false
      end

      it "does not recognize HTML files as collection files" do
        path = Pathname.new("test.html")
        expect(generator.collection_file?(path)).to be false
      end
    end

    describe "#select_source_collection_files" do
      let(:output_directory) { tmp_dir.realpath }
      let(:generator) do
        described_class.new(source_path, { output_dir: output_directory })
      end

      it "includes YAML collection files from source" do
        collection_files = generator.select_source_collection_files
        yaml_exts = [".yml", ".yaml"].freeze
        yaml_files = collection_files.select do |f|
          yaml_exts.include?(f.extname&.downcase)
        end
        expect(yaml_files).not_to be_empty
      end
    end

    context "without manifest file" do
      let(:output_directory) { tmp_dir.realpath }
      let(:asset_directory) { output_directory.join(asset_folder) }

      it "generates site with compiled documents" do
        described_class.generate!(
          source_path,
          { output_dir: output_directory },
          continue_without_fonts: true,
        )

        expect(asset_directory.exist?).to be true
        expect(Dir.glob(asset_directory.join("**", "*.html")).length).to be > 0
      end
    end

    context "with manifest file" do
      let(:output_directory) { tmp_dir.realpath }
      let(:asset_directory) { output_directory.join(asset_folder) }

      around(:each) do |example|
        template_path = source_path.join("your-custom-template-path")
        stylesheet_path = source_path.join("stylesheet-file-path")
        FileUtils.mkdir_p(template_path)
        File.write(File.join(template_path, "_index.liquid"),
                   "<html>{{ content }}</html>")
        File.write(stylesheet_path, "body { margin: 0; }")

        example.run
      ensure
        FileUtils.rm_rf(template_path)
        FileUtils.rm_f(stylesheet_path)
      end

      it "uses the manifest to compile documents" do
        described_class.generate!(
          source_path,
          { output_dir: output_directory,
            config: source_path.join("metanorma.yml") },
          continue_without_fonts: true,
        )

        expect(asset_directory.exist?).to be true

        collection = manifest.metanorma.collection
        expect(collection.name).not_to be_empty
        expect(collection.organization).not_to be_nil
      end
    end

    context "custom site template" do
      let(:output_directory) { tmp_dir.realpath }

      context "without manifest file" do
        it "generates site with custom template options" do
          Dir.mktmpdir("template-") do |template_tmp|
            stylesheet_path = File.join(template_tmp, "style.css")
            template_dir = File.join(template_tmp, "template")
            FileUtils.mkdir_p(template_dir)
            File.write(stylesheet_path, "body { margin: 0; }")
            File.write(File.join(template_dir, "_index.liquid"),
                       "<html>{{ content }}</html>")

            described_class.generate!(
              source_path,
              { output_dir: output_directory,
                template_dir: template_dir,
                stylesheet: stylesheet_path },
              continue_without_fonts: true,
            )

            expect(output_directory.exist?).to be true
          end
        end
      end

      context "with manifest file" do
        it "uses manifest template configuration" do
          manifest_dir = source_path
          template_path = manifest_dir.join("your-custom-template-path")
          stylesheet_path = manifest_dir.join("stylesheet-file-path")

          FileUtils.mkdir_p(template_path)
          File.write(File.join(template_path, "_index.liquid"),
                     "<html>{{ content }}</html>")
          File.write(stylesheet_path, "body { margin: 0; }")

          described_class.generate!(
            source_path,
            { output_dir: output_directory,
              config: source_path.join("metanorma.yml") },
            continue_without_fonts: true,
          )

          expect(output_directory.exist?).to be true
        ensure
          FileUtils.rm_rf(manifest_dir.join("your-custom-template-path"))
          FileUtils.rm_f(manifest_dir.join("stylesheet-file-path"))
        end
      end
    end

    it "raise error on fatal errors" do
      Dir.mktmpdir("fatal-test-") do |dir|
        bad_source = Pathname.new(dir).join("sources")
        bad_source.mkpath
        File.write(bad_source.join("broken.adoc"),
                   "= Broken\n\nNo document class specified.\n")

        bad_output = Pathname.new(dir).join("output")

        expect do
          described_class.generate!(
            bad_source,
            { output_dir: bad_output },
            continue_without_fonts: false,
          )
        end.to raise_error(Metanorma::Cli::Errors::FatalCompilationError)
      end
    end
  end
end
