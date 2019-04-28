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

        expect_document_to_include_base_templates(document)
        expect(file_exits?(document, "README.adoc")).to be_truthy
        expect(file_exits?(document, "document.adoc")).to be_truthy
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

        expect_document_to_include_base_templates(document)
        expect(file_exits?(document, "README.adoc")).to be_truthy
        expect(file_exits?(document, "document.adoc")).to be_truthy
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

    context "with local template" do
      it "success for existing template" do
        document = "./tmp/my-local-document"
        template = "./templates"

        capture_stdout {
          Metanorma::Cli::Generator.run(
              document,
              type: "csd",
              overwrite: true,
              doctype: "standard",
              template: template,
              )
        }

        expect_document_to_include_base_templates(document)
        expect(file_exits?(document, "README.adoc")).to be_truthy
        expect(file_exits?(document, "document.adoc")).to be_truthy
        expect(file_exits?(document, "sections/01-scope.adoc")).to be_truthy
      end

      it "raise and throws an exception for non existing dir" do
        document = "./tmp/my-local-not-exists-document"
        template = "./templates_not_exists"

        output = capture_stdout {
          Metanorma::Cli::Generator.run(
              document,
              type: "csd",
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

  def base_templates
    @base_templates ||= [
      "Gemfile",
      "Makefile",
      "deploy.sh",
      ".gitignore",
      ".travis.yml",
      "Makefile.win",
      "appveyor.yml",
      ".gitlab-ci.yml",
    ]
  end

  def expect_document_to_include_base_templates(document)
    base_templates.each do |template|
      expect(file_exits?(document, template)).to be_truthy, lambda { template }
    end
  end
end
