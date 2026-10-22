# frozen_string_literal: true

RSpec.describe Metanorma::Cli::SchemaSiteDetector do
  let(:detector) { described_class.new(manifest_path) }
  let(:dir) { Dir.mktmpdir }
  let(:manifest_path) { File.join(dir, "metanorma.yml") }

  after { FileUtils.remove_entry(dir) }

  context "with the dummy ISO 10303 fixture" do
    let(:manifest_path) do
      File.expand_path("../../fixtures/dummy_collection/metanorma.yml",
                       __dir__)
    end

    it "is schema-bearing" do
      expect(detector).to be_schema_bearing
    end
  end

  context "with a site listing only AsciiDoc sources" do
    before do
      write_file("metanorma.yml", <<~YAML)
        ---
        metanorma:
          source:
            files:
              - document.adoc
      YAML
      write_file("document.adoc", "= Document")
    end

    it "is not schema-bearing" do
      expect(detector).not_to be_schema_bearing
    end
  end

  context "with a collection manifest without schemas" do
    before do
      write_file("metanorma.yml", <<~YAML)
        ---
        metanorma:
          source:
            files:
              - collection.yml
      YAML
      write_file("collection.yml", <<~YAML)
        ---
        directives:
          - documents-inline
        bibdata:
          title:
            - language: en
              content: Plain collection
          type: collection
        manifest:
          level: collection
          docref:
            - fileref: document.adoc
              identifier: plain
      YAML
      write_file("document.adoc", "= Document")
    end

    it "is not schema-bearing" do
      expect(detector).not_to be_schema_bearing
    end
  end

  context "with a schemas-only source" do
    before do
      write_file("metanorma.yml", <<~YAML)
        ---
        metanorma:
          source:
            files:
              - collection.yml
      YAML
      write_file("collection.yml", <<~YAML)
        ---
        manifest:
          level: collection
          docref:
            - file: schemas/thing/collection.yml
              schemas-only: true
      YAML
      write_file("schemas/thing/collection.yml", <<~YAML)
        ---
        schemas-only: true
        file: thing.exp
      YAML
    end

    it "is schema-bearing" do
      expect(detector).to be_schema_bearing
    end
  end

  context "with a collection.yml that has a sibling schemas.yaml" do
    before do
      write_file("metanorma.yml", <<~YAML)
        ---
        metanorma:
          source:
            files:
              - library.yml
      YAML
      write_file("library.yml", <<~YAML)
        ---
        directives:
          - documents-inline
        manifest:
          level: collection
          docref:
            - file: documents/widget/collection.yml
      YAML
      write_file("documents/widget/collection.yml", <<~YAML)
        ---
        manifest:
          level: collection
          docref:
            - fileref: document.adoc
              identifier: widget
      YAML
      write_file("documents/widget/schemas.yaml", <<~YAML)
        ---
        schemas:
          widget:
            path: widget.exp
      YAML
      write_file("documents/widget/document.adoc", "= Document")
    end

    it "is schema-bearing" do
      expect(detector).to be_schema_bearing
    end
  end

  def write_file(relative_path, content)
    path = File.join(dir, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end
end
