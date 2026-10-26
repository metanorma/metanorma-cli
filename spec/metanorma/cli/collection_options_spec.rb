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
