require "spec_helper"

RSpec.describe Metanorma::Cli::Generator do
  describe ".run" do
    context "without existing tempaltes" do
      it "downloads and generate new document" do
        document = "./tmp/my-document"

        Metanorma::Cli::Generator.new(
          document, type: "csd", doctype: "standard", overwrite: true
        ).run

        expect(file_exits?(document, "Gemfile")).to be_truthy
        expect(file_exits?(document, "Makefile")).to be_truthy
        expect(file_exits?(document, "standard/README.adoc")).to be_truthy

        expect(
          file_exits?(document, "standard/sections/01-scope.adoc"),
        ).to be_truthy
      end
    end
  end

  def file_exits?(root, filename)
    File.exist?([root, filename].join("/"))
  end
end
