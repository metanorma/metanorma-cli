require "spec_helper"

RSpec.describe "Metanorma" do
  around(:each) do |example|
    Dir.mktmpdir("rspec-") do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "site generate" do
    it "generate a mini site" do
      output_dir = Dir.pwd
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate).and_call_original
      allow(Metanorma::Cli::Compiler).to receive(:compile)
      command = %W(site generate #{source_dir} -o #{output_dir})

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        source_dir.to_s, { output_dir: output_dir, no_progress: true }, no_progress: true
      )

      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .at_least(:once)
        .with(
          kind_of(String),
          hash_including(format: :asciidoc, output_dir: kind_of(Pathname))
        )
    end

    it "generate a mini site with extra compile args" do
      output_dir = Dir.pwd
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate).and_call_original
      allow(Metanorma::Cli::Compiler).to receive(:compile)
      command = %W(site generate #{source_dir} -o #{output_dir}
                   --continue-without-fonts -S)

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        source_dir.to_s,
        {
          output_dir: output_dir,
          no_progress: true,
          continue_without_fonts: true,
          strict: true,
        },
        continue_without_fonts: true,
        no_progress: true,
        strict: true,
      )

      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .at_least(:once)
        .with(
          kind_of(String),
          hash_including(
            format: :asciidoc,
            output_dir: kind_of(Pathname),
            continue_without_fonts: true,
            strict: true,
          ),
        )
    end

    it "usages pwd as default source path" do
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate)

      Metanorma::Cli.start(%w(site generate))

      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        Dir.pwd.to_s, any_args
      )
    end

    it "supports custom template for site" do
      template_dir = "./tmp/template"
      stylesheet_path = "./tmp/template/style.css"
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate)

      command = %W(
        site generate #{source_dir}
        --template-dir #{template_dir}
        --stylesheet #{stylesheet_path}
      )

      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        source_dir.to_s,
        hash_including(template_dir: template_dir, stylesheet: stylesheet_path),
        no_progress: true,
      )
    end
  end

  def source_dir
    @source_dir ||= File.expand_path(File.join(File.dirname(__dir__), "fixtures"))
  end
end
