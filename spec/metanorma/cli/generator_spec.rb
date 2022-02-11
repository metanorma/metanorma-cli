require "spec_helper"

RSpec.describe Metanorma::Cli::Generator do
  describe ".run" do
    context "default type templates" do
      it "downloads and creates new document" do
        document = @tmp_dir.join "my-document"

        Metanorma::Cli::Generator.run(
          document,
          type: "csd",
          doctype: "standard",
          overwrite: true,
        )

        expect_document_to_include_base_templates(document)
      end
    end

    # Note: `csd` is a deafult type and using it with custom tempalte
    # will fall back to the defalt one, so for the test purpose let's
    # use an invalid type called `ccsd`, just to distingue that our
    # test is actually working as expected and cloning the git repo.
    #
    context "with custom template" do
      it "downloads and create new document" do
        document = @tmp_dir.join "my-custom-csd"
        template = "https://github.com/metanorma/mn-templates-csd"

        Metanorma::Cli::Generator.run(
          document,
          type: "custom-csd",
          overwrite: true,
          doctype: "standard",
          template: template,
        )

        expect_document_to_include_base_templates(document)
      end
    end

    context "with invalid template" do
      it "raise and throws an exception" do
        document = @tmp_dir.join "my-invalid-document"
        template = "https://github.com/metanorma/mn-templates-invalid"

        output = capture_stdout do
          Metanorma::Cli::Generator.run(
            document,
            type: "new-csd",
            overwrite: true,
            doctype: "standard",
            template: template,
          )
        end

        expect(output).to include("Unable to generate document:")
        expect(output).to include(
          "please provide a valid `type` or a template URL",
        )
      end

      it "raise and throws a custom exception" do
        document = @tmp_dir.join "my-invalid-document"
        template = "https://github.com/metanorma/mn-templates-ogc"

        output = capture_stdout do
          Metanorma::Cli::Generator.run(
            document,
            type: "ogc",
            overwrite: true,
            doctype: "charter",
            template: template,
          )
        end

        expect(output).to include("Unable to generate document:")
        expect(output).not_to include(
          "please provide a valid `type` or a template URL",
        )
        expect(output).to include("can be downloaded from")
      end
    end

    context "with local template" do
      it "success for existing template" do
        document = @tmp_dir.join "my-local-document"
        template = [Dir.home, ".metanorma", "templates", "csd"].join("/")

        Metanorma::Cli::Generator.run(
          document,
          type: "csd",
          overwrite: true,
          doctype: "standard",
          template: template,
        )

        expect_document_to_include_base_templates(document)
      end
    end

    context "no write permission" do
      it "says it out loud with error message" do
        allow(Metanorma::Cli).to receive(:writable_templates_path?)
          .and_raise(Errno::EACCES)

        document = @tmp_dir.join "my-document"

        output = capture_stdout do
          Metanorma::Cli::Generator.run(
            document, type: "csd", doctype: "standard"
          )
        end

        expect(output).to include(
          "The current user does not have permission to write to this path",
        )
      end
    end
  end

  it "template dir priority: common > base" do
    document = @tmp_dir.join "priority-test"

    generator = Metanorma::Cli::Generator.new(
      document,
      type: "csd",
      doctype: "standard",
      overwrite: true,
    )
    allow(generator).to receive(:create_file)

    generator.run

    expect(generator).to have_received(:create_file)
      .once
      .with(end_with("common/Gemfile"), "Gemfile")
  end

  def file_exits?(root, filename)
    root.join(filename).exist?
  end

  def base_templates
    @base_templates ||= [
      "Gemfile",
      ".gitignore",
      ".github/workflows/docker.yml",
      ".github/workflows/generate.yml",
      ".gitlab-ci.yml",
    ]
  end

  def expect_document_to_include_base_templates(document)
    base_templates.each do |template|
      expect(file_exits?(document, template)).to be_truthy, lambda { template }
    end

    %w[README.adoc document.adoc sections/01-scope.adoc].each do |file|
      p "document=#{document} file=#{file}"
      expect(file_exits?(document, file)).to be_truthy
    end
  end
end
