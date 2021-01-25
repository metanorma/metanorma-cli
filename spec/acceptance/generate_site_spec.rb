require "spec_helper"

RSpec.describe "Metanorma" do
  describe "site generate" do
    it "generate a mini site" do
      output_dir = source_dir.join("site").to_s
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate)
      command = %W(site generate #{source_dir} -o #{output_dir})

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        source_dir.to_s, { output_dir: output_dir }, {}
      )
    end

    it "generate a mini site with extra compile args" do
      output_dir = source_dir.join("site").to_s
      allow(Metanorma::Cli::SiteGenerator).to receive(:generate)
      command = %W(site generate #{source_dir} -o #{output_dir} --continue-without-fonts)

      output = capture_stdout { Metanorma::Cli.start(command) }

      expect(output).to include("Site has been generated at #{output_dir}")
      expect(Metanorma::Cli::SiteGenerator).to have_received(:generate).with(
        source_dir.to_s,
        { output_dir: output_dir, continue_without_fonts: true },
        continue_without_fonts: true
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
    @source_dir ||= Metanorma::Cli.root_path.join("tmp")
  end
end
