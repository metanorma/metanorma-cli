require "spec_helper"

RSpec.describe Metanorma::Cli::GitTemplate do
  describe ".find_or_download_by" do
    context "with existing template" do
      it "returns the existing template" do
        Metanorma::Cli::GitTemplate.find_or_download_by("csd")

        template = Metanorma::Cli::GitTemplate.find_or_download_by("csd")

        expect(template.exist?).to be_truthy
        expect(template.to_s).to include("templates/csd")
      end
    end

    context "without an existing template" do
      it "downloads and return the new template" do
        Metanorma::Cli::GitTemplate.new("csd").remove!

        template = Metanorma::Cli::GitTemplate.find_or_download_by("csd")

        expect(template.exist?).to be_truthy
        expect(template.to_s).to include("templates/csd")
      end
    end
  end

  describe ".download" do
    it "downloads a remote metanorma template" do
      csd_template = "https://github.com/metanorma/mn-templates-csd"

      template = Metanorma::Cli::GitTemplate.download("csd", repo: csd_template)

      expect(template.exist?).to be_truthy
      expect(template.to_s).to include("templates/git/csd")
    end

    it "says it out loud for invalid template repository" do
      template_repo = "https://github.com/metanorma/mn-templates-csd-one"

      output = capture_stdout {
        Metanorma::Cli::GitTemplate.download("csd", repo: template_repo)
      }

      expect(output).to include("Invalid template repository:")
      expect(output).to include("Repository not found")
    end
  end
end
