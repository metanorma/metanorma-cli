require "spec_helper"

RSpec.describe Metanorma::Cli::Setup do
  describe ".run" do
    context "with existing fonts" do
      it "copy overs the existing fonts" do
        font_name = "FakeCalibri"

        allow(Metanorma::Cli).to receive(:fonts).and_return(fixture_fonts)
        Metanorma::Cli::Setup.run(font: font_name, term_agreement: true)

        expect(Metanorma::Cli.fonts.grep(/#{font_name}/i)).not_to be_nil
      end
    end

    context "with downloadale font" do
      it "downloads and copy over the font" do
        font_name = "FakeCalibri"

        stub_system_home_directory

        allow(Fontist::Font).to receive(:install).and_return(fixture_fonts)
        Metanorma::Cli::Setup.run(font: "CALIBRI.TTF", term_agreement: true)

        expect(Metanorma::Cli.fonts.grep(/#{font_name}/i)).not_to be_nil
      end
    end
  end

  def fixture_fonts
    [Metanorma::Cli.root_path.join("spec", "fixtures", "FakeCalibri.ttf").to_s]
  end
end
