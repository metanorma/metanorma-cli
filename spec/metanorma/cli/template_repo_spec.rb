require "spec_helper"

RSpec.describe Metanorma::Cli::TemplateRepo do
  describe ".add" do
    context "with valid template source" do
      it "adds the template to metanorma templates" do
        name = "iso"
        source = "https://github.com/metanorma/mn-templates-iso"
        stub_system_home_directory

        templates = Metanorma::Cli::TemplateRepo.add(
          name, source, overwrite: true
        )

        expect(templates.last[:name]).to eq(name)
        expect(templates.last[:source]).to eq(source)
      end
    end

    context "with duplicate template" do
      it "does override the existing template" do
        name = "iso"
        source = "https://github.com/metanorma/mn-templates-iso"

        expect do
          Metanorma::Cli::TemplateRepo.add(name, source)
          Metanorma::Cli::TemplateRepo.add(name, source)
        end.to raise_error(Metanorma::Cli::Errors::DuplicateTemplateError)
      end
    end
  end
end
