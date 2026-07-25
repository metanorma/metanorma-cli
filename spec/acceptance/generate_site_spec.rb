# frozen_string_literal: true

RSpec.describe "Metanorma" do
  let(:source_dir) { Pathname.new(__dir__).parent.join("fixtures") }

  around(:each) do |example|
    Dir.mktmpdir("rspec-") do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "site generate" do
    it "generate a mini site" do
      output_dir = Dir.pwd
      command = %W(site generate #{source_dir} -o #{output_dir}
                   --continue-without-fonts)

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      asset_dir = Pathname.new(output_dir).join("documents")
      expect(asset_dir.exist?).to be true
    end

    it "generate a mini site with extra compile args" do
      output_dir = Dir.pwd
      command = %W(site generate #{source_dir} -o #{output_dir}
                   --continue-without-fonts -S)

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      asset_dir = Pathname.new(output_dir).join("documents")
      expect(asset_dir.exist?).to be true
    end

    it "generate a mini site with selected output formats" do
      output_dir = Dir.pwd
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate!)
        .and_call_original
      allow(Metanorma::Cli::Compiler).to receive(:compile)
      command = %W(site generate #{source_dir} -o #{output_dir} -x rxl)

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .at_least(:once)
        .with(
          kind_of(String),
          hash_including(format: :asciidoc, extensions: "rxl"),
        )
    end

    it "usages pwd as default source path" do
      expect do
        Metanorma::Cli.start(%w(site generate --continue-without-fonts))
      end.not_to raise_error
    end

    it "supports custom template for site" do
      template_dir = "./tmp/template"
      stylesheet_path = "./tmp/template/style.css"
      FileUtils.mkdir_p(template_dir)
      File.write(stylesheet_path, "body { margin: 0; }")
      File.write(File.join(template_dir, "_index.liquid"),
                 "<html>{{ content }}</html>")

      command = %W(
        site generate #{source_dir}
        --template-dir #{template_dir}
        --stylesheet #{stylesheet_path}
        --continue-without-fonts
      )

      capture_stdout { Metanorma::Cli.start(command) }
    end
  end

  describe "failure" do
    it "raises FatalCompilationError on fatal error" do
      Dir.mktmpdir("fatal-acceptance-") do |dir|
        bad_source = Pathname.new(dir).join("sources")
        bad_source.mkpath
        File.write(bad_source.join("broken.adoc"),
                   "= Broken\n\nNo document class specified.\n")

        bad_output = Pathname.new(dir).join("output")

        expect do
          Metanorma::Cli::SiteGenerator.generate!(
            bad_source,
            { output_dir: bad_output },
          )
        end.to raise_error(Metanorma::Cli::Errors::FatalCompilationError)
      end
    end
  end
end
