require "spec_helper"

RSpec.describe "Metanorma" do
  describe "new document" do
    it "creates a new metanorma document" do
      allow(Metanorma::Cli::Generator).to receive(:run)

      command = %w(new -t iso -d standard ./tmp/my-iso-doc)
      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::Generator).to have_received(:run)
    end

    context "with :template option" do
      it "downloads the template and create new document" do
        allow(Metanorma::Cli::Generator).to receive(:run)

        command = %w(
          new
            -t csd
            -d standard
            -g https://github.com/metanorma/mn-templates-csd
            ./tmp/my-csd-doc
        )

        capture_stdout { Metanorma::Cli.start(command) }

        expect(Metanorma::Cli::Generator).to have_received(:run).
          with(
            "./tmp/my-csd-doc",
            doctype: "standard",
            overwrite: nil,
            template: "https://github.com/metanorma/mn-templates-csd",
            type: "csd",
        )
      end
    end
  end
end
