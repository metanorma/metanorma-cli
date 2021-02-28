require "spec_helper"

RSpec.describe "Metanorma" do
  describe "site generate" do
    it "generate a mini site" do
      output_dir = source_dir.join("site").to_s
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate).and_call_original
      allow(Metanorma::Cli::Compiler).to receive(:compile)
      command = %W(site generate #{source_dir} -o #{output_dir})

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        source_dir.to_s, { output_dir: output_dir }, {}
      )

      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .at_least(:once)
        .with(
          kind_of(String),
          hash_including(format: :asciidoc, output_dir: kind_of(Pathname))
        )
    end

    it "generate a mini site with extra compile args" do
      output_dir = source_dir.join("site").to_s
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate).and_call_original
      allow(Metanorma::Cli::Compiler).to receive(:compile)
      command = %W(site generate #{source_dir} -o #{output_dir} --continue-without-fonts)

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        source_dir.to_s,
        { output_dir: output_dir, continue_without_fonts: true },
        continue_without_fonts: true
      )

      expect(Metanorma::Cli::Compiler).to have_received(:compile)
        .at_least(:once)
        .with(
          kind_of(String),
          hash_including(format: :asciidoc, output_dir: kind_of(Pathname), continue_without_fonts: true)
        )
    end

    it "usages pwd as default source path" do
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate)
      command = %w(site generate)
      capture_stdout { Metanorma::Cli.start(command) }

      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        Dir.pwd.to_s, any_args
      )
    end
  end

  def source_dir
    @source_dir ||= Pathname.new Dir.tmpdir
  end
end
