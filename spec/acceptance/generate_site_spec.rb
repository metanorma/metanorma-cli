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
        source_dir.to_s, output_dir: output_dir
      )
    end
  end

  def source_dir
    @source_dir ||= Metanorma::Cli.root_path.join("tmp")
  end
end
