# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Cli::Collection do
  # `metanorma collection --help` parses no file, so extract_options_from_file
  # reached yaml_file.slice on nil and crashed the help path
  # (metanorma-cli regression found on 1.18.0.pre.alpha.2).
  it "does not crash when no options file is parsed" do
    file = File.join(Dir.mktmpdir, "notes.txt")
    File.write(file, "not yaml options")

    collection = described_class.new(file, {})

    expect { collection.send(:extract_options_from_file) }.not_to raise_error
  end

  it "takes coverpage, format and output_folder from the collection file" do
    dir = Dir.mktmpdir
    file = File.join(dir, "collection.yml")
    File.write(
      file,
      <<~YAML
        output_folder: site
        format: html
        manifest:
          title: T
      YAML
    )

    collection = described_class.new(file, {})
    collection.send(:extract_options_from_file)

    expect(collection.options["output_folder"]).to eq("site")
    expect(collection.options["format"]).to eq("html")
    expect(collection.options.key?("coverpage")).to be(false)
  end
end

RSpec.describe Metanorma::Cli::Collection, "#render manifest loading" do
  # metanorma-cli#494: an unloadable manifest surfaced as
  # `undefined method 'slice' for nil` instead of a reason.
  def render(path)
    described_class.new(path, {}).render
  end

  def manifest(name, content)
    path = File.join(Dir.mktmpdir, name)
    File.write(path, content)
    path
  end

  it "names the missing file" do
    expect { render("/nonexistent/collection.yml") }.to raise_error(
      Metanorma::Cli::Errors::FileNotFoundError,
      %r{manifest /nonexistent/collection.yml: file not found},
    )
  end

  it "hints at the argument order for `collection render x.yml`" do
    Dir.chdir(Dir.mktmpdir) do
      expect { render("render") }.to raise_error(
        Metanorma::Cli::Errors::FileNotFoundError,
        /metanorma collection collection.yml/,
      )
    end
  end

  it "rejects an empty YAML manifest" do
    expect { render(manifest("collection.yml", "")) }.to raise_error(
      Metanorma::Cli::Errors::CollectionManifestError,
      /expected a YAML mapping, got an empty document/,
    )
  end

  it "rejects a YAML manifest that is not a mapping" do
    expect { render(manifest("collection.yml", "- a\n- b\n")) }.to raise_error(
      Metanorma::Cli::Errors::CollectionManifestError, /got Array/
    )
  end

  it "reports YAML syntax errors as a manifest error" do
    expect { render(manifest("collection.yml", "a: [b\n")) }.to raise_error(
      Metanorma::Cli::Errors::CollectionManifestError,
      /cannot load collection manifest .*collection.yml: /,
    )
  end

  it "rejects unsupported manifest extensions" do
    expect { render(manifest("notes.txt", "x")) }.to raise_error(
      Metanorma::Cli::Errors::CollectionManifestError,
      /expected a .yml, .yaml or .xml file/,
    )
  end

  it "passes a loadable manifest on to the collection renderer" do
    path = manifest("collection.yml",
                    "date: 2026-01-01\nmanifest:\n  title: T\n")
    collection = described_class.new(path, {})
    renderer = double("collection", render: nil)
    allow(collection).to receive(:collection_file).and_return(renderer)

    collection.render

    expect(renderer).to have_received(:render)
  end
end

RSpec.describe Metanorma::Cli, ".start with an unloadable manifest" do
  it "prints the reason and exits non-zero" do
    path = File.join(Dir.mktmpdir, "collection.yml")
    File.write(path, "")

    expect do
      expect { described_class.start(["collection", path]) }
        .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
    end.to output(/Error: cannot load collection manifest/).to_stdout
  end
end
