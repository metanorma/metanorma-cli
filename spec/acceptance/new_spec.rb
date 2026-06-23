require "spec_helper"

RSpec.describe "Metanorma" do
  describe "new document" do
    around(:each) do |example|
      Dir.mktmpdir("rspec-") do |dir|
        Dir.chdir(dir) { example.run }
      end
    end

    it "creates a new metanorma document" do
      document = Pathname.new("my-csd-doc")

      command = %w(new -t csd -d standard my-csd-doc)
      capture_stdout { Metanorma::Cli.start(command) }

      expect(document.join("Gemfile").exist?).to be true
    end

    context "with :template option" do
      it "downloads the template and create new document" do
        document = Pathname.new("my-csd-doc")

        command = %w(
          new
          -t csd
          -d standard
          -l https://github.com/metanorma/mn-templates-csd
          my-csd-doc
        )

        capture_stdout { Metanorma::Cli.start(command) }

        expect(document.join("Gemfile").exist?).to be true
      end
    end
  end
end
