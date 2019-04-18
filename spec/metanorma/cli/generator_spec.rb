require "spec_helper"

RSpec.describe Metanorma::Cli::Generator do
  describe ".run" do
    context "default type templates" do
      it "downloads and creates new document" do
        document = "./tmp/my-document"

        capture_stdout {
          Metanorma::Cli::Generator.run(
            document, type: "csd", doctype: "standard",
            overwrite: true
          )
        }

        expect(file_exits?(document, "Gemfile")).to be_truthy
        expect(file_exits?(document, "Makefile")).to be_truthy
        expect(file_exits?(document, "README.adoc")).to be_truthy
        expect(file_exits?(document, "cc-document.adoc")).to be_truthy
        expect(file_exits?(document, "sections/01-scope.adoc")).to be_truthy
      end
    end

    context "with custom template" do
      it "downloads and create new document" do
        document = "./tmp/my-custom-csd"
        template = "https://github.com/metanorma/mn-templates-csd"

        capture_stdout {
          Metanorma::Cli::Generator.run(
            document,
            type: "csd",
            overwrite: true,
            doctype: "standard",
            template: template,
          )
        }

        expect(file_exits?(document, "Gemfile")).to be_truthy
        expect(file_exits?(document, "Makefile")).to be_truthy
        expect(file_exits?(document, "README.adoc")).to be_truthy
        expect(file_exits?(document, "cc-document.adoc")).to be_truthy
        expect(file_exits?(document, "sections/01-scope.adoc")).to be_truthy
      end
    end

    context "with invalid template" do
      it "raise and throws an exception" do
        document = "./tmp/my-invalid-document"
        template = "https://github.com/metanorma/mn-templates-invalid"

        output = capture_stdout {
          Metanorma::Cli::Generator.run(
            document,
            type: "nncsd",
            overwrite: true,
            doctype: "standard",
            template: template,
          )
        }

        expect(output).to include("Sorry, could not generate the document!")
      end
    end
  end

  def file_exits?(root, filename)
    File.exist?([root, filename].join("/"))
  end
end
