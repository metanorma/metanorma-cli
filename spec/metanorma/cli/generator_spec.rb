require "spec_helper"

RSpec.describe Metanorma::Cli::Generator do
  describe ".run" do
    context "without existing templates" do
      it "downloads and generate new document" do
        document = "./tmp/my-document"

        capture_stdout {
          Metanorma::Cli::Generator.run(
            document, type: "csd", doctype: "standard", overwrite: true
          )
        }

        expect(file_exits?(document, "Gemfile")).to be_truthy
        expect(file_exits?(document, "Makefile")).to be_truthy
        expect(file_exits?(document, "README.adoc")).to be_truthy
        expect(file_exits?(document, "cc-document.adoc")).to be_truthy
        expect(file_exits?(document, "sections/01-scope.adoc")).to be_truthy
      end
    end
  end

  def file_exits?(root, filename)
    File.exist?([root, filename].join("/"))
  end
end
